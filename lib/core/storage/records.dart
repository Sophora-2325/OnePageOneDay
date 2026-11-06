import 'dart:convert';

import '../../domain/training_scope.dart';

/// 内存中的状态记录；与数据库表、备份文件字段一一对应。
///
/// v3：每条学习记录都带 [goal]（备考目标）。备份文件里是显式字符串；
/// 数据库里通过 encodeScopedDay 编进 day 整数，兼容 1.0 的旧数据。

GoalId _goalOf(Map<String, dynamic> j) => goalIdFromKey(j['goal'] as String?) ?? GoalId.cet6;

String attemptKey(GoalId goal, int day, String kind, String readingId) =>
    '${goal.name}|$day|$kind|$readingId';
String draftKey(GoalId goal, int day, String kind) => '${goal.name}|$day|$kind';
String recordKey(GoalId goal, int day) => '${goal.name}|$day';

class AttemptRec {
  AttemptRec({
    required this.day,
    required this.kind,
    required this.readingId,
    GoalId? goal,
    Map<String, String>? answers,
    this.submitted = false,
    this.score,
    this.total,
    DateTime? updatedAt,
  })  : goal = goal ?? GoalId.cet6,
        answers = answers ?? {},
        updatedAt = updatedAt ?? DateTime.now();

  final int day;
  final String kind; // reading | listening
  final String readingId;
  GoalId goal;
  final Map<String, String> answers;
  bool submitted;
  int? score;
  int? total;
  DateTime updatedAt;

  String get key => attemptKey(goal, day, kind, readingId);

  Map<String, dynamic> toJson() => {
        'goal': goal.name,
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
        goal: _goalOf(j),
        day: (j['day'] as num).toInt(),
        kind: j['kind'] as String,
        readingId: j['readingId'] as String,
        answers: ((j['answers'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
        submitted: j['submitted'] as bool? ?? false,
        score: (j['score'] as num?)?.toInt(),
        total: (j['total'] as num?)?.toInt(),
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
      );
}

class DraftRec {
  DraftRec({
    required this.day,
    required this.kind,
    required this.body,
    GoalId? goal,
    DateTime? updatedAt,
  })  : goal = goal ?? GoalId.cet6,
        updatedAt = updatedAt ?? DateTime.now();

  final int day;
  final String kind; // translation | writing
  GoalId goal;
  String body;
  DateTime updatedAt;

  String get key => draftKey(goal, day, kind);

  Map<String, dynamic> toJson() => {
        'goal': goal.name,
        'day': day,
        'kind': kind,
        'body': body,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DraftRec.fromJson(Map<String, dynamic> j) => DraftRec(
        goal: _goalOf(j),
        day: (j['day'] as num).toInt(),
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
    GoalId? goal,
    DateTime? createdAt,
  })  : goal = goal ?? GoalId.cet6,
        createdAt = createdAt ?? DateTime.now();

  int? id;
  final int day;
  final String target; // r1 | r2 | writing
  final int paraIndex;
  final int start;
  final int end;
  final String quote;
  String note;
  GoalId goal;
  final DateTime createdAt;

  /// 用于导入去重：同一档、同一处原文只保留一条。
  String get identity => '${goal.name}|$day|$target|$paraIndex|$start|$end';

  Map<String, dynamic> toJson() => {
        'goal': goal.name,
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
        goal: _goalOf(j),
        day: (j['day'] as num).toInt(),
        target: j['target'] as String,
        paraIndex: (j['paraIndex'] as num).toInt(),
        start: (j['start'] as num).toInt(),
        end: (j['end'] as num).toInt(),
        quote: j['quote'] as String? ?? '',
        note: j['note'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}

class NoteRec {
  NoteRec({required this.day, required this.body, GoalId? goal, DateTime? updatedAt})
      : goal = goal ?? GoalId.cet6,
        updatedAt = updatedAt ?? DateTime.now();

  final int day;
  GoalId goal;
  String body;
  DateTime updatedAt;

  String get key => recordKey(goal, day);

  Map<String, dynamic> toJson() =>
      {'goal': goal.name, 'day': day, 'body': body, 'updatedAt': updatedAt.toIso8601String()};

  factory NoteRec.fromJson(Map<String, dynamic> j) => NoteRec(
        goal: _goalOf(j),
        day: (j['day'] as num).toInt(),
        body: j['body'] as String? ?? '',
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
      );
}

class ReviewRec {
  ReviewRec({
    required this.day,
    GoalId? goal,
    this.wrongReason = '',
    this.vocab = '',
    this.nextStep = '',
    Set<int>? scoring,
    this.done = false,
    DateTime? updatedAt,
  })  : goal = goal ?? GoalId.cet6,
        scoring = scoring ?? {},
        updatedAt = updatedAt ?? DateTime.now();

  final int day;
  GoalId goal;
  String wrongReason;
  String vocab;
  String nextStep;

  /// 翻译采分点勾选（下标）。
  final Set<int> scoring;
  bool done;
  DateTime updatedAt;

  String get key => recordKey(goal, day);

  String get scoringJson => jsonEncode(scoring.toList()..sort());

  Map<String, dynamic> toJson() => {
        'goal': goal.name,
        'day': day,
        'wrongReason': wrongReason,
        'vocab': vocab,
        'nextStep': nextStep,
        'scoring': scoring.toList()..sort(),
        'done': done,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ReviewRec.fromJson(Map<String, dynamic> j) => ReviewRec(
        goal: _goalOf(j),
        day: (j['day'] as num).toInt(),
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
  GeneratedDayRec({
    required this.day,
    required this.payload,
    this.model = '',
    GoalId? goal,
    DateTime? createdAt,
  })  : goal = goal ?? GoalId.cet6,
        createdAt = createdAt ?? DateTime.now();

  final int day;
  GoalId goal;
  final Map<String, dynamic> payload;
  final String model;
  final DateTime createdAt;

  String get key => recordKey(goal, day);

  String get theme => payload['theme']?.toString() ?? '';
  String get date => payload['date']?.toString() ?? '';

  Map<String, dynamic> toJson() => {
        'goal': goal.name,
        'day': day,
        'model': model,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
      };

  factory GeneratedDayRec.fromJson(Map<String, dynamic> j) => GeneratedDayRec(
        goal: _goalOf(j),
        day: (j['day'] as num).toInt(),
        payload: (j['payload'] as Map).cast<String, dynamic>(),
        model: j['model'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}
