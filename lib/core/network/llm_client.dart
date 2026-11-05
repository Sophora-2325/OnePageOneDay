// App 唯一的出网点：只请求用户自己填写的 OpenAI 兼容 baseUrl。
// 密钥只出现在单次请求头里；所有异常都转成不含请求细节的 LlmException，
// 不把 DioException（含 RequestOptions）往外抛，避免密钥进日志或崩溃栈。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../storage/secure.dart';

class ChatMessage {
  const ChatMessage(this.role, this.content);
  const ChatMessage.system(this.content) : role = 'system';
  const ChatMessage.user(this.content) : role = 'user';
  const ChatMessage.assistant(this.content) : role = 'assistant';

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

enum LlmErrorKind { invalidConfig, offline, unauthorized, rateLimited, timeout, badResponse, http, cancelled }

class LlmException implements Exception {
  const LlmException(this.kind, this.message, {this.status});

  final LlmErrorKind kind;
  final String message;
  final int? status;

  @override
  String toString() => message;
}

/// 模型调用抽象，生成引擎与选词翻译都只依赖它，便于用假模型单测。
abstract class ChatModel {
  Future<String> complete(List<ChatMessage> messages, {double temperature = 0.7, CancelToken? cancel});
}

/// 校验并补全请求地址：只接受 https；基础地址自动补 /chat/completions。
Uri resolveEndpoint(String baseUrl) {
  final raw = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  final uri = Uri.tryParse(raw);
  if (raw.isEmpty || uri == null || !uri.hasAuthority) {
    throw const LlmException(LlmErrorKind.invalidConfig, '请填写有效的 API 地址，例如 https://api.example.com/v1');
  }
  if (uri.scheme != 'https') {
    throw const LlmException(LlmErrorKind.invalidConfig, '只支持 https:// 开头的地址，避免密钥明文传输');
  }
  return raw.endsWith('/chat/completions') ? uri : Uri.parse('$raw/chat/completions');
}

class LlmClient implements ChatModel {
  LlmClient(
    this.config, {
    Dio? dio,
    this.timeout = const Duration(seconds: 180),
    this.backoff = const [Duration(seconds: 2), Duration(seconds: 4), Duration(seconds: 8)],
  }) : _dio = dio ?? Dio();

  final ApiConfig config;
  final Duration timeout;

  /// 429 限流时的退避间隔；不计入生成引擎的修复次数。
  final List<Duration> backoff;
  final Dio _dio;

  @override
  Future<String> complete(List<ChatMessage> messages, {double temperature = 0.7, CancelToken? cancel}) async {
    if (!config.isComplete) {
      throw const LlmException(LlmErrorKind.invalidConfig, '还没有配置模型 API，请到「我的 → 模型 API」填写');
    }
    final url = resolveEndpoint(config.baseUrl);
    for (var attempt = 0;; attempt++) {
      try {
        final res = await _dio.postUri<Object?>(
          url,
          data: {
            'model': config.model.trim(),
            'temperature': temperature,
            'messages': messages.map((m) => m.toJson()).toList(),
          },
          cancelToken: cancel,
          options: Options(
            headers: {'Authorization': 'Bearer ${config.apiKey.trim()}'},
            contentType: Headers.jsonContentType,
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: timeout,
            validateStatus: (_) => true,
          ),
        );
        final status = res.statusCode ?? 0;
        if (status == 429 && attempt < backoff.length) {
          await Future<void>.delayed(backoff[attempt]);
          continue;
        }
        _throwForStatus(status);
        return _extractContent(res.data);
      } on DioException catch (e) {
        throw _mapDio(e);
      } on SocketException {
        throw const LlmException(LlmErrorKind.offline, '网络不可用');
      }
    }
  }

  static void _throwForStatus(int status) {
    if (status >= 200 && status < 300) return;
    switch (status) {
      case 401:
      case 403:
        throw LlmException(LlmErrorKind.unauthorized, '密钥未通过验证（HTTP $status），请检查 API 密钥', status: status);
      case 404:
        throw LlmException(LlmErrorKind.http, '地址或模型名不存在（HTTP 404），请检查 API 地址与模型', status: status);
      case 429:
        throw LlmException(LlmErrorKind.rateLimited, '模型侧繁忙或额度不足（HTTP 429），稍后再试', status: status);
      default:
        throw LlmException(LlmErrorKind.http, '服务返回 HTTP $status，请检查地址、模型或额度', status: status);
    }
  }

  static LlmException _mapDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.cancel:
        return const LlmException(LlmErrorKind.cancelled, '已取消');
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const LlmException(LlmErrorKind.timeout, '请求超时');
      case DioExceptionType.badCertificate:
        return const LlmException(LlmErrorKind.http, '服务器证书无效，已拒绝连接');
      case DioExceptionType.connectionError:
        return const LlmException(LlmErrorKind.offline, '无法连接到 API 地址，请检查网络');
      default:
        return e.error is SocketException
            ? const LlmException(LlmErrorKind.offline, '网络不可用')
            : const LlmException(LlmErrorKind.http, '请求失败，请检查 API 地址');
    }
  }

  static String _extractContent(Object? body) {
    try {
      final data = body is String ? jsonDecode(body) : body as Map;
      final content = data['choices'][0]['message']['content'];
      final text = content is List
          ? content.map((p) => p is Map ? (p['text'] ?? '') : '$p').join()
          : (content ?? '').toString();
      if (text.trim().isEmpty) throw const FormatException();
      return text;
    } catch (_) {
      throw const LlmException(LlmErrorKind.badResponse, '服务没有返回文字内容，请确认接口兼容 Chat Completions');
    }
  }
}

/// 从模型输出里宽容地取出 JSON 对象：去掉思考块与 markdown 围栏、截取最外层花括号、修尾逗号。
Map<String, dynamic> extractJsonObject(String raw) {
  var text = raw.replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '');
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
  if (fence != null) text = fence.group(1)!;
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) throw const FormatException('没有找到 JSON 对象');
  text = text.substring(start, end + 1);
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    decoded = jsonDecode(text.replaceAllMapped(RegExp(r',(\s*[}\]])'), (m) => m.group(1)!));
  }
  if (decoded is! Map) throw const FormatException('顶层不是 JSON 对象');
  return decoded.cast<String, dynamic>();
}
