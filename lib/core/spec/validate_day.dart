// 质量门禁：逐条复刻 tools/validate-days.mjs 的规则与报错文案。
// 输入是原始 JSON（与 assets/days/day-XX.json 同构：阅读译文在 readings[].translation，
// 范文译文在 writing.translation），因为模型产出可能连类型都不对，不能先解析成 DayData。

import '../../domain/training_scope.dart';
import 'normalize.dart';

class ValidationIssue {
  const ValidationIssue(this.part, this.message);

  /// meta | r1 | r2 | translation | writing —— 定向修复按它分组。
  final String part;
  final String message;

  @override
  String toString() => message;
}

class ValidationReport {
  final List<ValidationIssue> errors = [];
  final List<ValidationIssue> warnings = [];

  bool get ok => errors.isEmpty;

  List<ValidationIssue> errorsFor(String part) => errors.where((e) => e.part == part).toList();

  Set<String> get failedParts => errors.map((e) => e.part).toSet();
}

int _words(Object? text) => text.toString().trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
int _cnChars(Object? text) => RegExp(r'[\u4e00-\u9fff]').allMatches(text.toString()).length;
String _str(Object? v) => v == null ? '' : v.toString();
bool _filled(Object? v) => v != null && v != false && _str(v).isNotEmpty;
bool _isInt(Object? v) => v is int || (v is double && v == v.roundToDouble());
String _js(Object? v) => v == null ? 'undefined' : v.toString();

class _Checker {
  _Checker(this.report, this.rule);

  final ValidationReport report;

  /// 各档内容规范；六级的取值与 1.0 完全一致，报错文案也不变。
  final GoalContentRule rule;
  String part = 'meta';

  void fail(String msg) => report.errors.add(ValidationIssue(part, msg));
  void warn(String msg) => report.warnings.add(ValidationIssue(part, msg));

  void checkDay(Map<String, dynamic> day) {
    final dayNo = day['day'];
    final prefix = 'Day ${_js(dayNo)}';
    part = 'meta';
    if (!_isInt(dayNo) || (dayNo as num) < 1) fail('$prefix: invalid day number');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(_str(day['date']))) fail('$prefix: invalid date');
    final week = day['week'];
    if (!_isInt(week) || (week as num) < 1 || week > 7) fail('$prefix: invalid week');
    if (!_filled(day['theme'])) fail('$prefix: missing theme');

    final readings = day['readings'];
    if (readings is! List || readings.length != 2) {
      fail('$prefix: expected exactly 2 readings');
    } else {
      for (var i = 0; i < readings.length; i++) {
        final r = readings[i];
        part = r is Map && _filled(r['id']) ? _str(r['id']) : 'r${i + 1}';
        checkReading(prefix, r, i);
        checkReadingTranslation(prefix, r);
      }
    }

    part = 'translation';
    checkTranslation(prefix, day['translation']);
    part = 'writing';
    checkWriting(prefix, day['writing']);
    checkWritingTranslation(prefix, day['writing']);
  }

  void checkReading(String dayPrefix, Object? reading, int index) {
    final prefix = '$dayPrefix / reading ${index + 1}';
    if (reading is! Map) return fail('$prefix: missing object');
    if (!_filled(reading['id'])) fail('$prefix: missing id');
    if (!_filled(reading['title'])) fail('$prefix: missing title');

    final paragraphs = reading['paragraphs'];
    if (paragraphs is! List || paragraphs.length < 4 || paragraphs.length > 6) {
      fail('$prefix: expected 4-6 paragraphs, got ${paragraphs is List ? paragraphs.length : 'none'}');
      return;
    }
    final paras = paragraphs.map(_str).toList();
    final actualWords = _words(paras.join(' '));
    if (actualWords < rule.minWords || actualWords > rule.maxWords) {
      fail('$prefix: $actualWords words, expected ${rule.wordRange}');
    }
    final declared = reading['wordCount'];
    if (declared is num && declared.isFinite && (declared - actualWords).abs() > 15) {
      warn('$prefix: declared wordCount ${_js(declared)} differs from actual $actualWords');
    }

    checkQuestions(reading['questions'], 5, paras, prefix);
    checkQuestions(reading['listeningQuestions'], 4, paras, '$prefix / listening');
    final stems = <String>{
      for (final q in (reading['questions'] is List ? reading['questions'] as List : const []))
        if (q is Map) normalizeText(_str(q['stem'])).toLowerCase(),
    };
    for (final q in (reading['listeningQuestions'] is List ? reading['listeningQuestions'] as List : const [])) {
      if (q is Map && stems.contains(normalizeText(_str(q['stem'])).toLowerCase())) {
        fail('$prefix: listening question duplicates a reading stem');
      }
    }
  }

  void checkQuestions(Object? questions, int count, List<String> paragraphs, String prefix) {
    if (questions is! List || questions.length != count) {
      fail('$prefix: expected $count questions, got ${questions is List ? questions.length : 'none'}');
      return;
    }
    final seen = <String>{};
    final answerCount = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final qPrefix = '$prefix / q${i + 1}';
      if (q is! Map) {
        fail('$qPrefix: missing object');
        continue;
      }
      final id = q['id'];
      if (!_filled(id)) fail('$qPrefix: missing id');
      if (_filled(id) && seen.contains(_str(id))) fail('$qPrefix: duplicate id ${_str(id)}');
      seen.add(_str(id));
      if (!_filled(q['type'])) fail('$qPrefix: missing type');
      if (!_filled(q['stem']) || _str(q['stem']).trim().length < 8) fail('$qPrefix: stem too short');

      final options = q['options'];
      if (options is! List || options.length != 4) {
        fail('$qPrefix: expected 4 options, got ${options is List ? options.length : 'none'}');
      } else if (options.any((o) => _str(o).trim().isEmpty)) {
        fail('$qPrefix: empty option');
      }

      final answer = q['answer'] is String ? q['answer'] as String : '';
      if (!RegExp(r'^[A-D]$').hasMatch(answer)) {
        fail('$qPrefix: answer must be A-D, got ${_js(q['answer'])}');
      } else {
        answerCount[answer] = answerCount[answer]! + 1;
      }

      final locate = q['locate'];
      if (locate is! Map || !_isInt(locate['para']) || !_filled(locate['quote'])) {
        fail('$qPrefix: missing locate');
        continue;
      }
      final para = (locate['para'] as num).toInt();
      if (para < 1 || para > paragraphs.length) {
        fail('$qPrefix: locate.para $para out of range 1-${paragraphs.length}');
        continue;
      }
      final paragraph = normalizeText(paragraphs[para - 1]);
      final quote = normalizeText(_str(locate['quote']));
      if (quote.length < 15) fail('$qPrefix: locate.quote too short');
      if (!paragraph.contains(quote)) {
        fail('$qPrefix: locate.quote is not a verbatim substring of paragraph $para');
      }
      if (!_filled(q['explain']) || _str(q['explain']).trim().length < 40) {
        fail('$qPrefix: explanation too short');
      }
    }
    final maxSame = answerCount.values.reduce((a, b) => a > b ? a : b);
    if (maxSame >= 4) {
      warn('$prefix: $maxSame answers share the same letter '
          '({"A":${answerCount['A']},"B":${answerCount['B']},"C":${answerCount['C']},"D":${answerCount['D']}})');
    }
  }

  void checkReadingTranslation(String dayPrefix, Object? reading) {
    if (reading is! Map || reading['paragraphs'] is! List) return;
    final id = _str(reading['id']);
    final count = (reading['paragraphs'] as List).length;
    final t = reading['translation'];
    if (t is! List || t.length != count) {
      fail('$dayPrefix / translations: $id should have $count translated paragraphs');
      return;
    }
    for (var i = 0; i < t.length; i++) {
      if (_str(t[i]).trim().length < 10) {
        fail('$dayPrefix / translations: $id paragraph ${i + 1} translation is empty or too short');
      }
    }
  }

  void checkTranslation(String dayPrefix, Object? t) {
    final prefix = '$dayPrefix / translation';
    if (t is! Map) return fail('$prefix: missing object');

    final chars = _cnChars(_js(t['chinese']));
    if (chars < rule.minHanzi || chars > rule.maxHanzi) {
      fail('$prefix: $chars Chinese characters, expected ${rule.hanziRange}');
    }

    final hints = t['hints'];
    if (hints is! List || hints.length < 3 || hints.length > 5) fail('$prefix: expected 3-5 hints');
    if (!_filled(t['reference'])) {
      fail('$prefix: missing reference translation');
    } else {
      final refWords = _words(t['reference']);
      if (refWords < rule.minRefWords || refWords > rule.maxRefWords) {
        fail('$prefix: reference has $refWords words, expected ${rule.refRange}');
      }
    }
    final points = t['scoringPoints'];
    if (points is! List || points.length < 4 || points.length > 6) {
      fail('$prefix: expected 4-6 scoring points');
    } else {
      for (var i = 0; i < points.length; i++) {
        final p = points[i];
        if (p is! Map || !_filled(p['zh']) || !_filled(p['en'])) fail('$prefix: scoring point ${i + 1} incomplete');
      }
    }
    final highlights = t['highlights'];
    if (highlights is! List || highlights.length < 3) fail('$prefix: expected at least 3 highlights');
  }

  void checkWriting(String dayPrefix, Object? w) {
    final prefix = '$dayPrefix / writing';
    if (w is! Map) return fail('$prefix: missing object');
    if (!_filled(w['topic'])) fail('$prefix: missing topic');
    if (!_filled(w['prompt'])) fail('$prefix: missing prompt');
    final essayWords = _words(_filled(w['modelEssay']) ? w['modelEssay'] : '');
    if (essayWords < rule.minEssayWords || essayWords > rule.maxEssayWords) {
      fail('$prefix: model essay has $essayWords words, expected ${rule.essayRange}');
    }
    final structure = w['structure'];
    if (structure is! List || structure.length != 3) fail('$prefix: expected 3 structure paragraphs');
    final expressions = w['expressions'];
    if (expressions is! List || expressions.length < 5) fail('$prefix: expected at least 5 expressions');
  }

  void checkWritingTranslation(String dayPrefix, Object? w) {
    if (w is! Map) return;
    final t = _str(w['translation']).trim();
    if (t.length < 20) {
      fail('$dayPrefix / translations: writing translation is missing or too short');
    } else if (t.split(RegExp(r'\n{2,}')).length != 3) {
      fail('$dayPrefix / translations: writing translation should have 3 paragraphs');
    }
  }
}

/// 解析该用哪一套规范：显式传入 > payload 自带 goal > 六级默认。
GoalContentRule ruleFor(Map<String, dynamic> day, GoalId? goal) =>
    goalOf(goal ?? goalIdFromKey(day['goal'] as String?) ?? GoalId.cet6).rule;

/// 整天校验；[ValidationReport.ok] 为 true 才允许落库。
ValidationReport validateDay(Map<String, dynamic> day, {GoalId? goal}) {
  final report = ValidationReport();
  _Checker(report, ruleFor(day, goal)).checkDay(day);
  return report;
}

/// 单篇阅读（含逐段译文）校验，供分段生成时定向修复。
ValidationReport validateReadingPart(
  Map<String, dynamic> reading, {
  required int dayNo,
  required int index,
  GoalId goal = GoalId.cet6,
}) {
  final report = ValidationReport();
  final c = _Checker(report, goalOf(goal).rule)..part = 'r${index + 1}';
  c.checkReading('Day $dayNo', reading, index);
  c.checkReadingTranslation('Day $dayNo', reading);
  return report;
}

ValidationReport validateTranslationPart(
  Map<String, dynamic> translation, {
  required int dayNo,
  GoalId goal = GoalId.cet6,
}) {
  final report = ValidationReport();
  (_Checker(report, goalOf(goal).rule)..part = 'translation').checkTranslation('Day $dayNo', translation);
  return report;
}

ValidationReport validateWritingPart(
  Map<String, dynamic> writing, {
  required int dayNo,
  GoalId goal = GoalId.cet6,
}) {
  final report = ValidationReport();
  final c = _Checker(report, goalOf(goal).rule)..part = 'writing';
  c.checkWriting('Day $dayNo', writing);
  c.checkWritingTranslation('Day $dayNo', writing);
  return report;
}
