import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cet6_app/core/generation/generation_engine.dart';
import 'package:cet6_app/core/network/llm_client.dart';
import 'package:cet6_app/core/spec/validate_day.dart';
import 'package:cet6_app/core/storage/secure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> loadDay(int n) =>
    (jsonDecode(File('assets/days/day-${n.toString().padLeft(2, '0')}.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();

Map<String, dynamic> clone(Object? o) => (jsonDecode(jsonEncode(o)) as Map).cast<String, dynamic>();

/// 按首条 user prompt 判断在生成哪一段，返回预置内容；[corrupt] 可在指定轮次把输出弄坏。
class FakeModel implements ChatModel {
  FakeModel(this.source, {this.corrupt});

  final Map<String, dynamic> source;
  final String? Function(String part, int round, Map<String, dynamic> good)? corrupt;
  final calls = <List<ChatMessage>>[];
  final _rounds = <String, int>{};

  String partOf(List<ChatMessage> m) {
    final p = m[1].content;
    if (p.contains('id = "r1"')) return 'r1';
    if (p.contains('id = "r2"')) return 'r2';
    if (p.contains('汉译英')) return 'translation';
    return 'writing';
  }

  @override
  Future<String> complete(List<ChatMessage> messages, {double temperature = 0.7, CancelToken? cancel}) async {
    calls.add(List.of(messages));
    final part = partOf(messages);
    final round = _rounds[part] = (_rounds[part] ?? -1) + 1;
    final readings = source['readings'] as List;
    final good = switch (part) {
      'r1' => {...clone(readings[0]), 'topic': '教育'},
      'r2' => {...clone(readings[1]), 'topic': '自然'},
      'translation' => clone(source['translation']),
      _ => clone(source['writing']),
    };
    final bad = corrupt?.call(part, round, good);
    return bad ?? '好的，以下是结果：\n```json\n${jsonEncode(good)}\n```';
  }
}

GenerationRequest request() => GenerationRequest(dayNo: 8, date: '2026-11-07', example: loadDay(7));

void main() {
  group('生成引擎', () {
    test('正常模型：四段各一次请求，产出通过整天质检', () async {
      final model = FakeModel(loadDay(3));
      final events = <GenEvent>[];
      final day = await GenerationEngine(model).generate(request(), onEvent: events.add);
      expect(model.calls.length, 4);
      expect(validateDay(day).ok, isTrue);
      expect(day['day'], 8);
      expect(day['date'], '2026-11-07');
      expect(day['theme'], '教育与自然');
      expect((day['readings'] as List).every((r) => !(r as Map).containsKey('topic')), isTrue);
      expect(events.last.message, '整天终检通过');
    });

    test('定向修复：只回传失败项，修好后通过', () async {
      final model = FakeModel(loadDay(3), corrupt: (part, round, good) {
        if (part != 'r1' || round > 0) return null;
        (good['questions'] as List)[2]['locate']['quote'] = 'A sentence the model invented out of thin air.';
        return jsonEncode(good);
      });
      final events = <GenEvent>[];
      final day = await GenerationEngine(model).generate(request(), onEvent: events.add);
      expect(validateDay(day).ok, isTrue);
      expect(model.calls.length, 5);
      final repair = events.firstWhere((e) => e.kind == GenEventKind.repair);
      expect(repair.message, '阅读 A 第 3 题定位引文不在原文中，正在定向修复');
      final repairCall = model.calls[1];
      expect(repairCall.last.content, contains('reading 1 / q3: locate.quote is not a verbatim substring'));
      expect(repairCall.length, 4, reason: 'system + 原始要求 + 上次输出 + 失败项，不累积历史');
    });

    test('JSON 坏掉计入修复次数，修好后通过', () async {
      final model = FakeModel(loadDay(3), corrupt: (part, round, good) => part == 'translation' && round == 0 ? '{"chinese": "被截断' : null);
      final day = await GenerationEngine(model).generate(request());
      expect(validateDay(day).ok, isTrue);
    });

    test('弱模型持续产坏题：3 次修复后放弃，坏题交付率 = 0', () async {
      final model = FakeModel(loadDay(3), corrupt: (part, round, good) {
        if (part != 'r2') return null;
        (good['paragraphs'] as List).removeLast();
        return jsonEncode(good);
      });
      await expectLater(
        GenerationEngine(model).generate(request()),
        throwsA(isA<GenerationFailed>().having((e) => e.message, 'message', '阅读 B修复 3 次后仍未通过质检')),
      );
      expect(model.calls.where((c) => model.partOf(c) == 'r2').length, 4);
      expect(model.calls.any((c) => model.partOf(c) == 'translation'), isFalse, reason: '失败即停，不再浪费请求');
    });

    test('永远返回非 JSON 也会终止', () async {
      final model = FakeModel(loadDay(3), corrupt: (_, _, _) => '抱歉，我无法完成。');
      await expectLater(GenerationEngine(model).generate(request()), throwsA(isA<GenerationFailed>()));
      expect(model.calls.length, 4);
    });

    test('鉴权失败直接上抛原因，供 UI 引导去教程', () async {
      final model = _ThrowingModel(const LlmException(LlmErrorKind.unauthorized, '密钥未通过验证'));
      await expectLater(
        GenerationEngine(model).generate(request()),
        throwsA(isA<GenerationFailed>().having((e) => e.cause?.kind, 'kind', LlmErrorKind.unauthorized)),
      );
    });

    test('每篇阅读都指定随机答案顺序，单个字母最多 2 次', () async {
      final model = FakeModel(loadDay(3));
      await GenerationEngine(model).generate(request());
      for (final part in ['r1', 'r2']) {
        final prompt = model.calls.firstWhere((c) => model.partOf(c) == part)[1].content;
        final m = RegExp(r'阅读题 ([A-D](?: [A-D]){4})；听力题 ([A-D](?: [A-D]){3})').firstMatch(prompt);
        expect(m, isNotNull, reason: part);
        final letters = m!.group(1)!.split(' ');
        for (final l in letters) {
          expect(letters.where((x) => x == l).length, lessThanOrEqualTo(2));
        }
      }
    });

    test('请求只含规范与示例，不含用户数据字段', () async {
      final model = FakeModel(loadDay(3));
      await GenerationEngine(model).generate(request());
      final sent = model.calls.expand((c) => c).map((m) => m.content).join('\n');
      for (final forbidden in ['answersJson', 'wrongReason', 'annotations', 'notes', 'apiKey', 'Bearer']) {
        expect(sent.contains(forbidden), isFalse, reason: forbidden);
      }
    });
  });

  group('宽容 JSON 提取', () {
    test('围栏、思考块、前后缀文字、尾逗号', () {
      expect(extractJsonObject('<think>先想想 {x}</think>结果：```json\n{"a": [1, 2,], "b": {"c": 1,},}\n```谢谢'), {
        'a': [1, 2],
        'b': {'c': 1},
      });
    });

    test('截断或没有对象时报 FormatException', () {
      expect(() => extractJsonObject('{"a": "被截'), throwsFormatException);
      expect(() => extractJsonObject('no json here'), throwsFormatException);
    });
  });

  group('LlmClient', () {
    test('只接受 https；基础地址自动补 /chat/completions', () {
      expect(resolveEndpoint('https://api.x.com/v1/').toString(), 'https://api.x.com/v1/chat/completions');
      expect(resolveEndpoint('https://api.x.com/v1/chat/completions').toString(), 'https://api.x.com/v1/chat/completions');
      expect(() => resolveEndpoint('http://api.x.com/v1'), throwsA(isA<LlmException>()));
      expect(() => resolveEndpoint('not a url'), throwsA(isA<LlmException>()));
    });

    test('ApiConfig.toString 不泄露密钥', () {
      const c = ApiConfig(baseUrl: 'https://a', model: 'm', apiKey: 'sk-1234567890abcdef');
      expect(c.toString().contains('1234567890'), isFalse);
      expect(c.maskedKey, 'sk-****cdef');
    });

    test('429 退避后重试成功；密钥只在请求头', () async {
      final adapter = _ScriptedAdapter([
        (429, '{}'),
        (200, jsonEncode({'choices': [{'message': {'content': '你好'}}]})),
      ]);
      final client = LlmClient(
        const ApiConfig(baseUrl: 'https://api.x.com/v1', model: 'm', apiKey: 'sk-secret'),
        dio: Dio()..httpClientAdapter = adapter,
        backoff: const [Duration.zero, Duration.zero],
      );
      expect(await client.complete(const [ChatMessage.user('hi')]), '你好');
      expect(adapter.requests.length, 2);
      final req = adapter.requests.first;
      expect(req.uri.toString(), 'https://api.x.com/v1/chat/completions');
      expect(req.headers['Authorization'], 'Bearer sk-secret');
      expect(req.body.contains('sk-secret'), isFalse);
    });

    test('401 → unauthorized；异常文本不含密钥', () async {
      final client = LlmClient(
        const ApiConfig(baseUrl: 'https://api.x.com/v1', model: 'm', apiKey: 'sk-secret'),
        dio: Dio()..httpClientAdapter = _ScriptedAdapter([(401, '{"error":"bad key sk-secret"}')]),
      );
      try {
        await client.complete(const [ChatMessage.user('hi')]);
        fail('应抛出异常');
      } on LlmException catch (e) {
        expect(e.kind, LlmErrorKind.unauthorized);
        expect(e.toString().contains('sk-secret'), isFalse);
      }
    });

    test('未配置时不发请求', () async {
      final adapter = _ScriptedAdapter([]);
      final client = LlmClient(ApiConfig.empty, dio: Dio()..httpClientAdapter = adapter);
      await expectLater(client.complete(const [ChatMessage.user('hi')]),
          throwsA(isA<LlmException>().having((e) => e.kind, 'kind', LlmErrorKind.invalidConfig)));
      expect(adapter.requests, isEmpty);
    });
  });
}

class _ThrowingModel implements ChatModel {
  _ThrowingModel(this.error);
  final LlmException error;

  @override
  Future<String> complete(List<ChatMessage> messages, {double temperature = 0.7, CancelToken? cancel}) async => throw error;
}

class _Recorded {
  _Recorded(this.uri, this.headers, this.body);
  final Uri uri;
  final Map<String, dynamic> headers;
  final String body;
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.script);

  final List<(int, String)> script;
  final requests = <_Recorded>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final bytes = requestStream == null ? <int>[] : (await requestStream.toList()).expand((b) => b).toList();
    requests.add(_Recorded(options.uri, Map.of(options.headers), utf8.decode(bytes)));
    final (status, body) = script[requests.length - 1];
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    });
  }

  @override
  void close({bool force = false}) {}
}
