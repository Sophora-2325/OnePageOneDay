import 'dart:convert';

/// 内存中的状态记录；与数据库表、备份文件字段一一对应。

class AttemptRec {
  AttemptRec({
    required this.day,
    required this.kind,
    required this.readingId,
    Map<String, String>? answers,
    this.submitted = false,
    this.score,
    this.total,
    DateTime? updatedAt,
  })  : answers = answers ?? {},
        updatedAt = updatedAt ?? DateTime.now();

  final int day;
  final String kind; // reading | listening
  final String readingId;
  final Map<String, String> answers;
  bool submitted;
  int? score;
  int? total;
  DateTime updatedAt;

  String get key => attemptKey(day, kind, readingId);

  Map<String, dynamic> toJson() => {
        'day': day,
        'kind': kind,
        'readingId': readingId,
        'answers': answers,
        'submitted': submitted,
        'score': score,
        'total': total,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AttemptRec.fromJson(Map<String, dynamic> j) => AttemptRec(
        day: j['day'] as int,
        kind: j['kind'] as String,
        readingId: j['readingId'] as String,
        answers: ((j['answers'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
        submitted: j['submitted'] as bool? ?? false,
        score: j['score'] as int?,
        total: j['total'] as int?,
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
      );
}

String attemptKey(int day, String kind, String readingId) => '$day|$kind|$readingId';
String draftKey(int day, String kind) => '$day|$kind';

class DraftRec {
  DraftRec({required this.day, required this.kind, required this.body, DateTime? updatedAt})
      : updatedAt = updatedAt ?? DateTime.now();

  final int day;
  final String kind; // translation | writing
  String body;
  DateTime updatedAt;

  String get key => draftKey(day, kind);

  Map<String, dynamic> toJson() =>
      {'day': day, 'kind': kind, 'body': body, 'updatedAt': updatedAt.toIso8601String()};

  factory DraftRec.fromJson(Map<String, dynamic> j) => DraftRec(
        day: j['day'] as int,
        kind: j['kind'] as String,
        body: j['body'] as String? ?? '',
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
      );
}

class AnnotationRec {
  AnnotationRec({
    this.id,
    required this.day,
    required this.target,
    required this.paraIndex,
    required this.start,
    required this.end,
    required this.quote,
    required this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int? id;
  final int day;
  final String target; // r1 | r2 | writing
  final int paraIndex;
  final int start;
  final int end;
  final String quote;
  String note;
  final DateTime createdAt;

  /// 用于导入去重：同一处原文只保留一条。
  String get identity => '$day|$target|$paraIndex|$start|$end';

  Map<String, dynamic> toJson() => {
        'day': day,
        'target': target,
        'paraIndex': paraIndex,
        'start': start,
        'end': end,
        'quote': quote,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AnnotationRec.fromJson(Map<String, dynamic> j) => AnnotationRec(
        day: j['day'] as int,
        target: j['target'] as String,
        paraIndex: j['paraIndex'] as int,
        start: j['start'] as int,
        end: j['end'] as int,
        quote: j['quote'] as String? ?? '',
        note: j['note'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}

class NoteRec {
  NoteRec({required this.day, required this.body, DateTime? updatedAt}) : updatedAt = updatedAt ?? DateTime.now();

  final int day;
  String body;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {'day': day, 'body': body, 'updatedAt': updatedAt.toIso8601String()};

  factory NoteRec.fromJson(Map<String, dynamic> j) => NoteRec(
        day: j['day'] as int,
        body: j['body'] as String? ?? '',
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
      );
}

class ReviewRec {
  ReviewRec({
    required this.day,
    this.wrongReason = '',
    this.vocab = '',
    this.nextStep = '',
    Set<int>? scoring,
    this.done = false,
    DateTime? updatedAt,
  })  : scoring = scoring ?? {},
        updatedAt = updatedAt ?? DateTime.now();

  final int day;
  String wrongReason;
  String vocab;
  String nextStep;

  /// 翻译采分点勾选（下标）。
  final Set<int> scoring;
  bool done;
  DateTime updatedAt;

  String get scoringJson => jsonEncode(scoring.toList()..sort());

  Map<String, dynamic> toJson() => {
        'day': day,
        'wrongReason': wrongReason,
        'vocab': vocab,
        'nextStep': nextStep,
        'scoring': scoring.toList()..sort(),
        'done': done,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ReviewRec.fromJson(Map<String, dynamic> j) => ReviewRec(
        day: j['day'] as int,
        wrongReason: j['wrongReason'] as String? ?? '',
        vocab: j['vocab'] as String? ?? '',
        nextStep: j['nextStep'] as String? ?? '',
        scoring: ((j['scoring'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet(),
        done: j['done'] as bool? ?? false,
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
      );
}

/// 端侧生成并通过质检的一天；[payload] 与 assets/days/day-XX.json 同构。
class GeneratedDayRec {
  GeneratedDayRec({required this.day, required this.payload, this.model = '', DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  final int day;
  final Map<String, dynamic> payload;
  final String model;
  final DateTime createdAt;

  String get theme => payload['theme']?.toString() ?? '';
  String get date => payload['date']?.toString() ?? '';

  Map<String, dynamic> toJson() => {
        'day': day,
        'model': model,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
      };

  factory GeneratedDayRec.fromJson(Map<String, dynamic> j) => GeneratedDayRec(
        day: (j['day'] as num).toInt(),
        payload: (j['payload'] as Map).cast<String, dynamic>(),
        model: j['model'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}
