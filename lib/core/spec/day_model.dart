// 与「内容规范.md」字段一一对应；数据由 tool/convert_days.mjs 生成。

List<String> _strings(Object? v) => (v as List? ?? const []).map((e) => e.toString()).toList();

class DayIndexEntry {
  const DayIndexEntry({
    required this.day,
    required this.date,
    required this.week,
    required this.theme,
    required this.file,
    this.generated = false,
  });

  final int day;
  final String date;
  final int week;
  final String theme;
  final String file;

  /// 端侧 AI 生成（已过质检）的题包；预置题为 false。
  final bool generated;

  factory DayIndexEntry.fromJson(Map<String, dynamic> j) => DayIndexEntry(
        day: j['day'] as int,
        date: j['date'] as String,
        week: j['week'] as int,
        theme: j['theme'] as String,
        file: j['file'] as String,
      );
}

class Question {
  const Question({
    required this.id,
    required this.type,
    required this.stem,
    required this.options,
    required this.answer,
    required this.locatePara,
    required this.locateQuote,
    required this.explain,
  });

  final String id;
  final String type;
  final String stem;
  final List<String> options;
  final String answer;

  /// 从 1 开始的段落号。
  final int locatePara;
  final String locateQuote;
  final String explain;

  factory Question.fromJson(Map<String, dynamic> j) {
    final locate = (j['locate'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Question(
      id: j['id'] as String,
      type: j['type'] as String? ?? '',
      stem: j['stem'] as String,
      options: _strings(j['options']),
      answer: j['answer'] as String,
      locatePara: (locate['para'] as num?)?.toInt() ?? 1,
      locateQuote: locate['quote'] as String? ?? '',
      explain: j['explain'] as String? ?? '',
    );
  }
}

class Reading {
  const Reading({
    required this.id,
    required this.title,
    required this.wordCount,
    required this.paragraphs,
    required this.questions,
    required this.listeningQuestions,
    required this.translation,
  });

  final String id;
  final String title;
  final int wordCount;
  final List<String> paragraphs;
  final List<Question> questions;
  final List<Question> listeningQuestions;

  /// 逐段中文翻译，段数与 [paragraphs] 一致；可能为空。
  final List<String> translation;

  String get label => id == 'r1' ? '阅读 A' : '阅读 B';

  /// 紧凑控件（计时条、A/B 切换 Chip）用的短名，与「翻译 / 写作 / 笔记」等宽。
  /// 完整句式（标注合集、ScoreBanner、判分提示）仍用 [label]。
  String get shortLabel => id == 'r1' ? '文A' : '文B';

  factory Reading.fromJson(Map<String, dynamic> j) => Reading(
        id: j['id'] as String,
        title: j['title'] as String,
        wordCount: (j['wordCount'] as num?)?.toInt() ?? 0,
        paragraphs: _strings(j['paragraphs']),
        questions: (j['questions'] as List).map((e) => Question.fromJson((e as Map).cast())).toList(),
        listeningQuestions:
            (j['listeningQuestions'] as List? ?? const []).map((e) => Question.fromJson((e as Map).cast())).toList(),
        translation: _strings(j['translation']),
      );
}

class ScoringPoint {
  const ScoringPoint({required this.zh, required this.en});
  final String zh;
  final String en;
}

class TranslationTask {
  const TranslationTask({
    required this.chinese,
    required this.hints,
    required this.reference,
    required this.scoringPoints,
    required this.highlights,
  });

  final String chinese;
  final List<String> hints;
  final String reference;
  final List<ScoringPoint> scoringPoints;
  final List<String> highlights;

  factory TranslationTask.fromJson(Map<String, dynamic> j) => TranslationTask(
        chinese: j['chinese'] as String,
        hints: _strings(j['hints']),
        reference: j['reference'] as String,
        scoringPoints: (j['scoringPoints'] as List? ?? const [])
            .map((e) => ScoringPoint(zh: (e as Map)['zh'].toString(), en: e['en'].toString()))
            .toList(),
        highlights: _strings(j['highlights']),
      );
}

class WritingTask {
  const WritingTask({
    required this.topic,
    required this.prompt,
    required this.requirements,
    required this.outlineHints,
    required this.modelEssay,
    required this.structure,
    required this.expressions,
    required this.translation,
  });

  final String topic;
  final String prompt;
  final List<String> requirements;
  final List<String> outlineHints;
  final String modelEssay;
  final List<String> structure;
  final List<String> expressions;

  /// 范文中文译文，段落以空行分隔。
  final String translation;

  List<String> get essayParagraphs =>
      modelEssay.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

  List<String> get translationParagraphs =>
      translation.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

  factory WritingTask.fromJson(Map<String, dynamic> j) => WritingTask(
        topic: j['topic'] as String,
        prompt: j['prompt'] as String? ?? '',
        requirements: _strings(j['requirements']),
        outlineHints: _strings(j['outlineHints']),
        modelEssay: j['modelEssay'] as String,
        structure: _strings(j['structure']),
        expressions: _strings(j['expressions']),
        translation: j['translation'] as String? ?? '',
      );
}

class DayData {
  const DayData({
    required this.day,
    required this.date,
    required this.week,
    required this.theme,
    required this.readings,
    required this.translation,
    required this.writing,
  });

  final int day;
  final String date;
  final int week;
  final String theme;
  final List<Reading> readings;
  final TranslationTask translation;
  final WritingTask writing;

  Reading reading(String id) => readings.firstWhere((r) => r.id == id);

  factory DayData.fromJson(Map<String, dynamic> j) => DayData(
        day: j['day'] as int,
        date: j['date'] as String,
        week: (j['week'] as num?)?.toInt() ?? 1,
        theme: j['theme'] as String,
        readings: (j['readings'] as List).map((e) => Reading.fromJson((e as Map).cast())).toList(),
        translation: TranslationTask.fromJson((j['translation'] as Map).cast()),
        writing: WritingTask.fromJson((j['writing'] as Map).cast()),
      );
}
