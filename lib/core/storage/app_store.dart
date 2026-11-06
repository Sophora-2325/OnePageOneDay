import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../domain/training_scope.dart';
import '../backup/backup_codec.dart';
import 'db.dart';
import 'records.dart';

/// 全部本地学习数据：内存缓存 + 写穿到 SQLite。数据量很小，启动时一次性读入。
///
/// v3：所有学习记录按「备考目标」隔离。公开 API 仍只接收逻辑训练日 [day]，
/// 目标由 [goal] 隐式决定；调用方（今日 / 题库 / 复盘 / 我的）无需改动。
/// 数据库 day 列存 encodeScopedDay，六级占 0 槽，1.0 的旧数据零迁移。
class AppStore extends ChangeNotifier {
  AppStore(this._db);

  final AppDatabase _db;

  final Map<String, AttemptRec> _attempts = {};
  final Map<String, DraftRec> _drafts = {};
  final List<AnnotationRec> _annotations = [];
  final Map<String, NoteRec> _notes = {};
  final Map<String, ReviewRec> _reviews = {};
  final Map<String, String> _settings = {};
  final Map<String, GeneratedDayRec> _generated = {};
  final Map<String, Timer> _debouncers = {};

  GoalId _goal = GoalId.cet6;
  bool _loaded = false;

  /// 当前训练档。由 scope.goal 设置驱动，切换目标后所有读写自动换档。
  GoalId get goal => _goal;
  bool get loaded => _loaded;

  /// 展开状态也按档隔离，否则两档的同一天会互相串。
  String revealKey(int day, String kind) => 'reveal.${_goal.name}.$day.$kind';

  Future<void> load() async {
    for (final r in await _db.select(_db.settings).get()) {
      _settings[r.key] = r.value;
    }
    _goal = goalIdFromKey(_settings[TrainingScope.keyGoal]) ?? GoalId.cet6;
    await _migrateLegacyRevealFlags();

    for (final r in await _db.select(_db.attempts).get()) {
      final (goal: g, day: d) = decodeScopedDay(r.day);
      final rec = AttemptRec(
        goal: g,
        day: d,
        kind: r.kind,
        readingId: r.readingId,
        answers: (jsonDecode(r.answersJson) as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        submitted: r.submitted,
        score: r.score,
        total: r.total,
        updatedAt: r.updatedAt,
      );
      _attempts[rec.key] = rec;
    }
    for (final r in await _db.select(_db.drafts).get()) {
      final (goal: g, day: d) = decodeScopedDay(r.day);
      final rec = DraftRec(goal: g, day: d, kind: r.kind, body: r.body, updatedAt: r.updatedAt);
      _drafts[rec.key] = rec;
    }
    for (final r in await _db.select(_db.annotations).get()) {
      final (goal: g, day: d) = decodeScopedDay(r.day);
      _annotations.add(AnnotationRec(
        goal: g,
        id: r.id,
        day: d,
        target: r.target,
        paraIndex: r.paraIndex,
        start: r.startOffset,
        end: r.endOffset,
        quote: r.quote,
        note: r.note,
        createdAt: r.createdAt,
      ));
    }
    for (final r in await _db.select(_db.notes).get()) {
      final (goal: g, day: d) = decodeScopedDay(r.day);
      final rec = NoteRec(goal: g, day: d, body: r.body, updatedAt: r.updatedAt);
      _notes[rec.key] = rec;
    }
    for (final r in await _db.select(_db.reviews).get()) {
      final (goal: g, day: d) = decodeScopedDay(r.day);
      final rec = ReviewRec(
        goal: g,
        day: d,
        wrongReason: r.wrongReason,
        vocab: r.vocab,
        nextStep: r.nextStep,
        scoring: (jsonDecode(r.scoringJson) as List).map((e) => (e as num).toInt()).toSet(),
        done: r.done,
        updatedAt: r.updatedAt,
      );
      _reviews[rec.key] = rec;
    }
    for (final r in await _db.select(_db.generatedDays).get()) {
      final (goal: g, day: d) = decodeScopedDay(r.day);
      final rec = GeneratedDayRec(
        goal: g,
        day: d,
        payload: (jsonDecode(r.payloadJson) as Map).cast<String, dynamic>(),
        model: r.model,
        createdAt: r.createdAt,
      );
      _generated[rec.key] = rec;
    }
    _loaded = true;
    notifyListeners();
  }

  /// 1.0 的展开状态键是 `reveal.<day>.<kind>`（无目标），统一补成六级。
  Future<void> _migrateLegacyRevealFlags() async {
    final legacy = _settings.keys.where((k) => RegExp(r'^reveal\.\d+\.').hasMatch(k)).toList();
    for (final k in legacy) {
      final migrated = k.replaceFirst('reveal.', 'reveal.${GoalId.cet6.name}.');
      _settings[migrated] = _settings[k]!;
      _settings.remove(k);
      await _db.into(_db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(key: migrated, value: _settings[migrated]!),
          );
      await (_db.delete(_db.settings)..where((t) => t.key.equals(k))).go();
    }
  }

  // ---------------- 作答 ----------------

  AttemptRec attempt(int day, String kind, String readingId) =>
      _attempts.putIfAbsent(
          attemptKey(_goal, day, kind, readingId),
          () => AttemptRec(goal: _goal, day: day, kind: kind, readingId: readingId));

  AttemptRec? peekAttempt(int day, String kind, String readingId) =>
      _attempts[attemptKey(_goal, day, kind, readingId)];

  Iterable<AttemptRec> get attempts => _attempts.values.where((a) => a.goal == _goal);
  Iterable<AttemptRec> attemptsFor(GoalId goal) => _attempts.values.where((a) => a.goal == goal);

  void answer(int day, String kind, String readingId, String questionId, String letter) {
    final a = attempt(day, kind, readingId);
    if (a.submitted) return;
    a.answers[questionId] = letter;
    a.updatedAt = DateTime.now();
    _saveAttempt(a);
    notifyListeners();
  }

  void submit(int day, String kind, String readingId, {required int score, required int total}) {
    final a = attempt(day, kind, readingId)
      ..submitted = true
      ..score = score
      ..total = total
      ..updatedAt = DateTime.now();
    _saveAttempt(a);
    notifyListeners();
  }

  void redo(int day, String kind, String readingId) {
    final a = attempt(day, kind, readingId)
      ..answers.clear()
      ..submitted = false
      ..score = null
      ..total = null
      ..updatedAt = DateTime.now();
    _saveAttempt(a);
    notifyListeners();
  }

  void _saveAttempt(AttemptRec a) {
    _db.into(_db.attempts).insertOnConflictUpdate(AttemptsCompanion.insert(
          day: encodeScopedDay(a.goal, a.day),
          kind: a.kind,
          readingId: a.readingId,
          answersJson: Value(jsonEncode(a.answers)),
          submitted: Value(a.submitted),
          score: Value(a.score),
          total: Value(a.total),
          updatedAt: a.updatedAt,
        ));
  }

  // ---------------- 草稿 ----------------

  String draft(int day, String kind) => _drafts[draftKey(_goal, day, kind)]?.body ?? '';

  void setDraft(int day, String kind, String body) {
    final rec = _drafts.putIfAbsent(
        draftKey(_goal, day, kind), () => DraftRec(goal: _goal, day: day, kind: kind, body: ''))
      ..body = body
      ..updatedAt = DateTime.now();
    _debounce('draft|${rec.key}', () => _saveDraft(rec));
    notifyListeners();
  }

  void _saveDraft(DraftRec d) {
    _db.into(_db.drafts).insertOnConflictUpdate(DraftsCompanion.insert(
          day: encodeScopedDay(d.goal, d.day),
          kind: d.kind,
          body: d.body,
          updatedAt: d.updatedAt,
        ));
  }

  // ---------------- 标注 ----------------

  List<AnnotationRec> annotationsFor(int day, [String? target]) => _annotations
      .where((a) => a.goal == _goal && a.day == day && (target == null || a.target == target))
      .toList();

  List<AnnotationRec> get allAnnotations => List.unmodifiable(_annotations);

  Future<void> addAnnotation(AnnotationRec a) async {
    a.goal = _goal;
    _annotations.add(a);
    notifyListeners();
    a.id = await _db.into(_db.annotations).insert(AnnotationsCompanion.insert(
          day: encodeScopedDay(a.goal, a.day),
          target: a.target,
          paraIndex: a.paraIndex,
          startOffset: a.start,
          endOffset: a.end,
          quote: a.quote,
          note: a.note,
          createdAt: a.createdAt,
        ));
  }

  void updateAnnotation(AnnotationRec a, String note) {
    a.note = note;
    if (a.id != null) {
      (_db.update(_db.annotations)..where((t) => t.id.equals(a.id!)))
          .write(AnnotationsCompanion(note: Value(note)));
    }
    notifyListeners();
  }

  void deleteAnnotation(AnnotationRec a) {
    _annotations.remove(a);
    if (a.id != null) {
      (_db.delete(_db.annotations)..where((t) => t.id.equals(a.id!))).go();
    }
    notifyListeners();
  }

  // ---------------- 笔记 ----------------

  String note(int day) => _notes[recordKey(_goal, day)]?.body ?? '';

  Map<int, NoteRec> get notes => {
        for (final n in _notes.values.where((n) => n.goal == _goal)) n.day: n,
      };

  void setNote(int day, String body) {
    final rec = _notes.putIfAbsent(recordKey(_goal, day), () => NoteRec(goal: _goal, day: day, body: ''))
      ..body = body
      ..updatedAt = DateTime.now();
    _debounce('note|${rec.key}', () => _saveNote(rec));
    notifyListeners();
  }

  Future<void> flushNote(int day) async {
    final key = recordKey(_goal, day);
    _debouncers.remove('note|$key')?.cancel();
    final rec = _notes[key];
    if (rec != null) await _saveNote(rec);
  }

  Future<void> _saveNote(NoteRec n) => _db.into(_db.notes).insertOnConflictUpdate(NotesCompanion.insert(
        day: Value(encodeScopedDay(n.goal, n.day)),
        body: n.body,
        updatedAt: n.updatedAt,
      ));

  // ---------------- 复盘 ----------------

  ReviewRec review(int day) =>
      _reviews.putIfAbsent(recordKey(_goal, day), () => ReviewRec(goal: _goal, day: day));

  ReviewRec? peekReview(int day) => _reviews[recordKey(_goal, day)];

  ReviewRec? reviewFor(GoalId goal, int day) => _reviews[recordKey(goal, day)];

  Iterable<ReviewRec> get reviews => _reviews.values.where((r) => r.goal == _goal);
  Iterable<ReviewRec> reviewsFor(GoalId goal) => _reviews.values.where((r) => r.goal == goal);

  void updateReview(int day, void Function(ReviewRec r) change, {bool debounce = true}) {
    final r = review(day);
    change(r);
    r.updatedAt = DateTime.now();
    if (debounce) {
      _debounce('review|${r.key}', () => _saveReview(r));
    } else {
      _saveReview(r);
    }
    notifyListeners();
  }

  void _saveReview(ReviewRec r) {
    _db.into(_db.reviews).insertOnConflictUpdate(ReviewsCompanion.insert(
          day: Value(encodeScopedDay(r.goal, r.day)),
          wrongReason: Value(r.wrongReason),
          vocab: Value(r.vocab),
          nextStep: Value(r.nextStep),
          scoringJson: Value(r.scoringJson),
          done: Value(r.done),
          updatedAt: r.updatedAt,
        ));
  }

  // ---------------- 设置 ----------------

  String? setting(String key) => _settings[key];

  bool flag(String key) => _settings[key] == '1';

  void setSetting(String key, String value) {
    final changedGoal = key == TrainingScope.keyGoal && _settings[key] != value;
    _settings[key] = value;
    if (changedGoal) {
      _goal = goalIdFromKey(value) ?? GoalId.cet6;
    }
    _db.into(_db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
    notifyListeners();
  }

  void setFlag(String key, bool on) => setSetting(key, on ? '1' : '0');

  // ---------------- 生成题包 ----------------

  /// 当前档的题包，键为逻辑训练日；供 DayRepository 使用。
  Map<int, GeneratedDayRec> get generatedDays => {
        for (final g in _generated.values.where((g) => g.goal == _goal)) g.day: g,
      };

  Iterable<GeneratedDayRec> generatedFor(GoalId goal) => _generated.values.where((g) => g.goal == goal);

  /// 调用方必须先用 validateDay 通过质检；这里不再兜底，避免两处规则漂移。
  Future<void> addGeneratedDay(GeneratedDayRec rec) async {
    rec.goal = _goal;
    _generated[rec.key] = rec;
    notifyListeners();
    await _saveGenerated(rec);
  }

  Future<void> _saveGenerated(GeneratedDayRec rec) => _db.into(_db.generatedDays).insertOnConflictUpdate(
        GeneratedDaysCompanion.insert(
          day: Value(encodeScopedDay(rec.goal, rec.day)),
          date: rec.payload['date'].toString(),
          theme: rec.payload['theme'].toString(),
          payloadJson: jsonEncode(rec.payload),
          model: Value(rec.model),
          createdAt: rec.createdAt,
        ),
      );

  /// 删除当前档生成的一天及其全部学习记录，避免日后同号新题包继承旧作答。
  Future<void> deleteGeneratedDay(int day) async {
    final scoped = encodeScopedDay(_goal, day);
    _generated.remove(recordKey(_goal, day));
    _annotations.removeWhere((a) => a.goal == _goal && a.day == day);
    _notes.remove(recordKey(_goal, day));
    await resetDay(day);
    await (_db.delete(_db.generatedDays)..where((t) => t.day.equals(scoped))).go();
    await (_db.delete(_db.annotations)..where((t) => t.day.equals(scoped))).go();
    await (_db.delete(_db.notes)..where((t) => t.day.equals(scoped))).go();
  }

  // ---------------- 重置与备份 ----------------

  /// 重置本档本日阅读 / 听力作答、草稿、复盘和展开状态；保留标注与笔记。
  Future<void> resetDay(int day) async {
    final scoped = encodeScopedDay(_goal, day);
    _attempts.removeWhere((_, a) => a.goal == _goal && a.day == day);
    _drafts.removeWhere((_, d) => d.goal == _goal && d.day == day);
    _reviews.remove(recordKey(_goal, day));
    final prefix = 'reveal.${_goal.name}.$day.';
    final legacyPrefix = 'reveal.$day.'; // 1.0 升级上来的旧键
    final flagKeys = _settings.keys
        .where((k) => k.startsWith(prefix) || k.startsWith(legacyPrefix))
        .toList();
    for (final k in flagKeys) {
      _settings.remove(k);
    }
    notifyListeners();
    await (_db.delete(_db.attempts)..where((t) => t.day.equals(scoped))).go();
    await (_db.delete(_db.drafts)..where((t) => t.day.equals(scoped))).go();
    await (_db.delete(_db.reviews)..where((t) => t.day.equals(scoped))).go();
    await (_db.delete(_db.settings)..where((t) => t.key.like('$prefix%'))).go();
    await (_db.delete(_db.settings)..where((t) => t.key.like('$legacyPrefix%'))).go();
  }

  /// 备份包含**全部档**的数据；导出时不带任何 API 凭据。
  BackupData snapshot() => BackupData(
        attempts: _attempts.values.toList(),
        drafts: _drafts.values.toList(),
        annotations: List.of(_annotations),
        notes: _notes.values.toList(),
        reviews: _reviews.values.toList(),
        settings: Map.of(_settings),
        generatedDays: _generated.values.toList(),
        exportedAt: DateTime.now(),
      );

  /// 按记录合并覆盖，不删除本机已有数据；v1 备份的记录统一归入六级。
  Future<void> importBackup(BackupData data) async {
    await _flushAll();
    for (final g in data.generatedDays) {
      _generated[g.key] = g;
      await _saveGenerated(g);
    }
    for (final a in data.attempts) {
      _attempts[a.key] = a;
      _saveAttempt(a);
    }
    for (final d in data.drafts) {
      _drafts[d.key] = d;
      _saveDraft(d);
    }
    for (final n in data.notes) {
      _notes[n.key] = n;
      await _saveNote(n);
    }
    for (final r in data.reviews) {
      _reviews[r.key] = r;
      _saveReview(r);
    }
    for (final a in data.annotations) {
      final existing = _annotations.where((e) => e.identity == a.identity).firstOrNull;
      if (existing != null) {
        updateAnnotation(existing, a.note);
      } else {
        _annotations.add(a);
        a.id = await _db.into(_db.annotations).insert(AnnotationsCompanion.insert(
              day: encodeScopedDay(a.goal, a.day),
              target: a.target,
              paraIndex: a.paraIndex,
              startOffset: a.start,
              endOffset: a.end,
              quote: a.quote,
              note: a.note,
              createdAt: a.createdAt,
            ));
      }
    }
    for (final e in data.settings.entries) {
      if (!isSensitiveSettingKey(e.key)) setSetting(e.key, e.value);
    }
    notifyListeners();
  }

  /// 立刻把所有防抖中的写入落库（切档、导出、进入后台前调用）。
  Future<void> flush() => _flushAll();

  void _debounce(String key, VoidCallback action) {
    _debouncers.remove(key)?.cancel();
    _debouncers[key] = Timer(const Duration(milliseconds: 300), () {
      _debouncers.remove(key);
      action();
    });
  }

  Future<void> _flushAll() async {
    for (final t in _debouncers.values) {
      t.cancel();
    }
    _debouncers.clear();
    for (final d in _drafts.values) {
      _saveDraft(d);
    }
    for (final n in _notes.values) {
      await _saveNote(n);
    }
    for (final r in _reviews.values) {
      _saveReview(r);
    }
  }

  @override
  void dispose() {
    _flushAll();
    super.dispose();
  }
}
