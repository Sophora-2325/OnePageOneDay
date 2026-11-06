// 端侧生成引擎：分段请求 → 宽容 JSON 提取 → 校验门禁 → 定向修复（最多 3 次）→ 整天终检。
// 任一环节失败都抛 GenerationFailed，由调用方回落预置题；坏题交付率必须为 0。

import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../network/llm_client.dart';
import '../spec/prompt.dart';
import '../spec/validate_day.dart';
import '../../domain/grading.dart';
import '../../domain/training_scope.dart';

enum GenStage { readingA, readingB, translation, writing, finalCheck }

extension GenStageLabel on GenStage {
  String get label => switch (this) {
        GenStage.readingA => '阅读 A',
        GenStage.readingB => '阅读 B',
        GenStage.translation => '翻译',
        GenStage.writing => '写作',
        GenStage.finalCheck => '整天质检',
      };
}

enum GenEventKind { start, repair, passed }

class GenEvent {
  const GenEvent(this.stage, this.kind, this.message);

  final GenStage stage;
  final GenEventKind kind;
  final String message;
}

class GenerationFailed implements Exception {
  const GenerationFailed(this.message, {this.cause});

  final String message;

  /// 网络 / 鉴权类错误时为对应的 [LlmException]，质检失败时为 null。
  final LlmException? cause;

  @override
  String toString() => message;
}

class GenerationRequest {
  const GenerationRequest({
    required this.dayNo,
    required this.date,
    required this.example,
    this.avoidTitles = const [],
    this.avoidWritingTopics = const [],
    this.focus,
    this.goal = GoalId.cet6,
    this.diff = DiffLevel.steady,
  });

  final int dayNo;
  final String date;

  /// 本档预置题包中的一天（原始 JSON），用作 few-shot 结构示例。
  final Map<String, dynamic> example;
  final List<String> avoidTitles;
  final List<String> avoidWritingTopics;
  final String? focus;

  /// 目标档与本次生效的难度；决定 prompt、topic 池和质检规则。
  final GoalId goal;
  final DiffLevel diff;
}

class GenerationEngine {
  GenerationEngine(this.model, {this.maxRepairs = 3, Random? random}) : _random = random ?? Random();

  final ChatModel model;
  final Random _random;

  /// 每篇随机指定答案字母顺序（单个字母最多 2 次），避免模型每篇都用同一套规律。
  List<String> _answerKey(int n) {
    final pool = [for (final l in optionLetters) ...[l, l]]..shuffle(_random);
    return pool.take(n).toList();
  }

  /// 每段在首次请求之外允许的修复轮数（JSON 解析失败也计入）。
  final int maxRepairs;

  Future<Map<String, dynamic>> generate(
    GenerationRequest req, {
    void Function(GenEvent event)? onEvent,
    CancelToken? cancel,
  }) async {
    void emit(GenStage s, GenEventKind k, String m) => onEvent?.call(GenEvent(s, k, m));
    final dayNo = req.dayNo;
    final spec = goalOf(req.goal);
    final rule = spec.rule;
    final exReadings = (req.example['readings'] as List).cast<Map<String, dynamic>>();
    final topicA = rule.topics[dayNo % rule.topics.length];

    final readingA = await _part(
      GenStage.readingA,
      readingPrompt(
        id: 'r1',
        dayNo: dayNo,
        example: {...exReadings[0], 'id': 'r1', 'topic': '教育'},
        avoidTitles: req.avoidTitles,
        focus: req.focus,
        answerKey: _answerKey(5),
        listeningKey: _answerKey(4),
        goal: req.goal,
        diff: req.diff,
      ),
      (j) => validateReadingPart(j, dayNo: dayNo, index: 0, goal: req.goal),
      emit,
      cancel,
      goal: req.goal,
      fix: (j) => _fixReading(j, 'r1'),
    );

    final readingB = await _part(
      GenStage.readingB,
      readingPrompt(
        id: 'r2',
        dayNo: dayNo,
        example: {...exReadings[1], 'id': 'r2', 'topic': '自然'},
        avoidTitles: [...req.avoidTitles, readingA['title'].toString()],
        otherTopic: readingA['topic']?.toString() ?? topicA,
        answerKey: _answerKey(5),
        listeningKey: _answerKey(4),
        goal: req.goal,
        diff: req.diff,
      ),
      (j) => validateReadingPart(j, dayNo: dayNo, index: 1, goal: req.goal),
      emit,
      cancel,
      goal: req.goal,
      fix: (j) => _fixReading(j, 'r2'),
    );

    final translation = await _part(
      GenStage.translation,
      translationPrompt(
        example: (req.example['translation'] as Map).cast(),
        topic: rule.translationTopics[dayNo % rule.translationTopics.length],
        goal: req.goal,
      ),
      (j) => validateTranslationPart(j, dayNo: dayNo, goal: req.goal),
      emit,
      cancel,
      goal: req.goal,
    );

    final writing = await _part(
      GenStage.writing,
      writingPrompt(
        example: (req.example['writing'] as Map).cast(),
        kind: rule.writingKinds[dayNo % rule.writingKinds.length],
        avoidTopics: req.avoidWritingTopics,
        goal: req.goal,
      ),
      (j) => validateWritingPart(j, dayNo: dayNo, goal: req.goal),
      emit,
      cancel,
      goal: req.goal,
      fix: _fixWriting,
    );

    final themeA = readingA.remove('topic')?.toString().trim();
    final themeB = readingB.remove('topic')?.toString().trim();
    final day = <String, dynamic>{
      'goal': req.goal.name,
      'diff': req.diff.name,
      'day': dayNo,
      'date': req.date,
      'week': ((dayNo - 1) ~/ 7) % 7 + 1,
      'theme': [themeA, themeB].where((t) => t != null && t.isNotEmpty).join('与'),
      'readings': [readingA, readingB],
      'translation': translation,
      'writing': writing,
    };
    if ((day['theme'] as String).isEmpty) day['theme'] = readingA['title'];

    emit(GenStage.finalCheck, GenEventKind.start, '整天终检');
    final report = validateDay(day, goal: req.goal);
    if (!report.ok) {
      throw GenerationFailed('整天终检未通过：${describeIssue(report.errors.first.message)}');
    }
    emit(GenStage.finalCheck, GenEventKind.passed, '整天终检通过');
    return day;
  }

  Future<Map<String, dynamic>> _part(
    GenStage stage,
    String prompt,
    ValidationReport Function(Map<String, dynamic>) validate,
    void Function(GenStage, GenEventKind, String) emit,
    CancelToken? cancel, {
    required GoalId goal,
    Map<String, dynamic> Function(Map<String, dynamic>)? fix,
  }) async {
    final messages = <ChatMessage>[ChatMessage.system(systemPromptFor(goal)), ChatMessage.user(prompt)];
    emit(stage, GenEventKind.start, '正在生成${stage.label}');
    for (var round = 0; round <= maxRepairs; round++) {
      final String raw;
      try {
        raw = await model.complete(messages, cancel: cancel);
      } on LlmException catch (e) {
        throw GenerationFailed(e.message, cause: e);
      }
      Map<String, dynamic> json;
      try {
        json = extractJsonObject(raw);
      } on FormatException {
        if (round == maxRepairs) break;
        emit(stage, GenEventKind.repair, '${stage.label}：模型返回格式不对，正在让它重写');
        messages
          ..removeRange(2, messages.length)
          ..add(const ChatMessage.user(parseRepairPrompt));
        continue;
      }
      if (fix != null) json = fix(json);
      final report = validate(json);
      if (report.ok) {
        emit(stage, GenEventKind.passed, '${stage.label}通过质检');
        return json;
      }
      if (round == maxRepairs) break;
      final errs = report.errors.map((e) => e.message).toList();
      emit(stage, GenEventKind.repair,
          '${describeIssue(errs.first)}${errs.length > 1 ? ' 等 ${errs.length} 处' : ''}，正在定向修复');
      messages
        ..removeRange(2, messages.length)
        ..add(ChatMessage.assistant(jsonEncode(json)))
        ..add(ChatMessage.user(repairPrompt(errs, goal: goal)));
    }
    throw GenerationFailed('${stage.label}修复 $maxRepairs 次后仍未通过质检');
  }
}

/// 只做不影响质量判断的确定性整理：统一 id、重算词数、规范答案与段号类型、拼接译文。
Map<String, dynamic> _fixReading(Map<String, dynamic> r, String id) {
  r['id'] = id;
  final paras = r['paragraphs'];
  if (paras is List) r['wordCount'] = countWords(paras.map((p) => '$p').join(' '));
  void fixQuestions(String key, String prefix) {
    final qs = r[key];
    if (qs is! List) return;
    for (var i = 0; i < qs.length; i++) {
      final q = qs[i];
      if (q is! Map) continue;
      q['id'] = '$prefix${i + 1}';
      if (q['answer'] is String) q['answer'] = (q['answer'] as String).trim().toUpperCase();
      final loc = q['locate'];
      if (loc is Map && loc['para'] is String) loc['para'] = int.tryParse(loc['para'] as String) ?? loc['para'];
    }
  }

  fixQuestions('questions', 'q');
  fixQuestions('listeningQuestions', 'l');
  return r;
}

Map<String, dynamic> _fixWriting(Map<String, dynamic> w) {
  final t = w['translation'];
  if (t is List) w['translation'] = t.map((p) => '$p'.trim()).join('\n\n');
  final essay = w['modelEssay'];
  if (essay is List) w['modelEssay'] = essay.map((p) => '$p'.trim()).join('\n\n');
  return w;
}

/// 把校验器的英文报错翻成给用户看的中文，建立「为什么修」的信任。
String describeIssue(String msg) {
  String where(String s) {
    final m = RegExp(r'reading (\d)( / listening)?(?: / q(\d+))?').firstMatch(s);
    if (m == null) return '';
    final article = m.group(1) == '1' ? '阅读 A' : '阅读 B';
    final kind = m.group(2) != null ? '听读' : '';
    return m.group(3) != null ? '$article $kind第 ${m.group(3)} 题' : '$article$kind';
  }

  final w = where(msg);
  if (msg.contains('locate.quote is not a verbatim substring')) return '$w定位引文不在原文中';
  if (msg.contains('locate.para') && msg.contains('out of range')) return '$w定位段号越界';
  if (msg.contains('locate.quote too short')) return '$w定位引文太短';
  if (msg.contains('missing locate')) return '$w缺少定位';
  if (msg.contains('explanation too short')) return '$w解析太短';
  if (msg.contains('answer must be A-D')) return '$w答案不是 A–D';
  if (msg.contains('options')) return '$w选项数量不对';
  if (msg.contains('duplicates a reading stem')) return '$w听读题与阅读题重复';
  final words = RegExp(r'(\d+) words, expected (\d+-\d+)').firstMatch(msg);
  if (words != null) return '$w词数 ${words.group(1)}，要求 ${words.group(2)!.replaceAll('-', '–')}';
  if (msg.contains('paragraphs, got')) return '$w段落数不在 4–6';
  if (msg.contains('questions, got')) return '$w题量不对';
  if (msg.contains('translated paragraphs')) return '${msg.contains('r1') ? '阅读 A' : '阅读 B'}译文段数与原文不一致';
  if (msg.contains('writing translation')) return '范文译文不是 3 段';
  final cn = RegExp(r'(\d+) Chinese characters, expected (\d+-\d+)').firstMatch(msg);
  if (cn != null) return '翻译原文 ${cn.group(1)} 字，要求 ${cn.group(2)!.replaceAll('-', '–')}';
  if (msg.contains('scoring point')) return '采分点不完整或数量不对';
  if (msg.contains('reference')) return '参考译文词数不对';
  if (msg.contains('hints')) return '翻译提示词数量不对';
  if (msg.contains('highlights')) return '亮点表达不足 3 个';
  final essay = RegExp(r'model essay has (\d+) words, expected (\d+-\d+)').firstMatch(msg);
  if (essay != null) return '范文 ${essay.group(1)} 词，要求 ${essay.group(2)!.replaceAll('-', '–')}';
  if (msg.contains('structure')) return '写作结构不是 3 条';
  if (msg.contains('expressions')) return '可复用表达不足 5 条';
  return msg;
}
