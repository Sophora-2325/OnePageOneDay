import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../backup/backup_codec.dart';
import 'db.dart';
import 'records.dart';

/// 全部本地学习数据：内存缓存 + 写穿到 SQLite。数据量很小，启动时一次性读入。
class AppStore extends ChangeNotifier {
  AppStore(this._db);

  final AppDatabase _db;

  final Map<String, AttemptRec> _attempts = {};
  final Map<String, DraftRec> _drafts = {};
  final List<AnnotationRec> _annotations = [];
  final Map<int, NoteRec> _notes = {};
  final Map<int, ReviewRec> _reviews = {};
  final Map<String, String> _settings = {};
  final Map<int, GeneratedDayRec> _generated = {};
  final Map<String, Timer> _debouncers = {};

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    for (final r in await _db.select(_db.attempts).get()) {
      final rec = AttemptRec(
        day: r.day,
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
      final rec = DraftRec(day: r.day, kind: r.kind, body: r.body, updatedAt: r.updatedAt);
      _drafts[rec.key] = rec;
    }
    for (final r in await _db.select(_db.annotations).get()) {
      _annotations.add(AnnotationRec(
        id: r.id,
        day: r.day,
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
      _notes[r.day] = NoteRec(day: r.day, body: r.body, updatedAt: r.updatedAt);
    }
    for (final r in await _db.select(_db.reviews).get()) {
      _reviews[r.day] = ReviewRec(
        day: r.day,
        wrongReason: r.wrongReason,
        vocab: r.vocab,
        nextStep: r.nextStep,
        scoring: (jsonDecode(r.scoringJson) as List).map((e) => (e as num).toInt()).toSet(),
        done: r.done,
        updatedAt: r.updatedAt,
      );
    }
    for (final r in await _db.select(_db.settings).get()) {
      _settings[r.key] = r.value;
    }
    for (final r in await _db.select(_db.generatedDays).get()) {
      _generated[r.day] = GeneratedDayRec(
        day: r.day,
        payload: (jsonDecode(r.payloadJson) as Map).cast<String, dynamic>(),
        model: r.model,
        createdAt: r.createdAt,
      );
    }
    _loaded = true;
    notifyListeners();
  }

  // ---------------- 作答 ----------------

  AttemptRec attempt(int day, String kind, String readingId) =>
      _attempts.putIfAbsent(attemptKey(day, kind, readingId), () => AttemptRec(day: day, kind: kind, readingId: readingId));

  AttemptRec? peekAttempt(int day, String kind, String readingId) => _attempts[attemptKey(day, kind, readingId)];

  Iterable<AttemptRec> get attempts => _attempts.values;

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
      day: a.day,
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

  String draft(int day, String kind) => _drafts[draftKey(day, kind)]?.body ?? '';

  void setDraft(int day, String kind, String body) {
    final rec = _drafts.putIfAbsent(draftKey(day, kind), () => DraftRec(day: day, kind: kind, body: ''))
      ..body = body
      ..updatedAt = DateTime.now();
    _debounce('draft|${rec.key}', () => _saveDraft(rec));
    notifyListeners();
  }

  void _saveDraft(DraftRec d) {
    _db.into(_db.drafts).insertOnConflictUpdate(
          DraftsCompanion.insert(day: d.day, kind: d.kind, body: d.body, updatedAt: d.updatedAt),
        );
  }

  // ---------------- 标注 ----------------

  List<AnnotationRec> annotationsFor(int day, [String? target]) =>
      _annotations.where((a) => a.day == day && (target == null || a.target == target)).toList();

  List<AnnotationRec> get allAnnotations => List.unmodifiable(_annotations);

  Future<void> addAnnotation(AnnotationRec a) async {
    _annotations.add(a);
    notifyListeners();
    a.id = await _db.into(_db.annotations).insert(AnnotationsCompanion.insert(
          day: a.day,
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
      (_db.update(_db.annotations)..where((t) => t.id.equals(a.id!))).write(AnnotationsCompanion(note: Value(note)));
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

  String note(int day) => _notes[day]?.body ?? '';

  Map<int, NoteRec> get notes => Map.unmodifiable(_notes);

  void setNote(int day, String body) {
    final rec = _notes.putIfAbsent(day, () => NoteRec(day: day, body: ''))
      ..body = body
      ..updatedAt = DateTime.now();
    _debounce('note|$day', () => _saveNote(rec));
    notifyListeners();
  }

  Future<void> flushNote(int day) async {
    _debouncers.remove('note|$day')?.cancel();
    final rec = _notes[day];
    if (rec != null) await _saveNote(rec);
  }

  Future<void> _saveNote(NoteRec n) => _db
      .into(_db.notes)
      .insertOnConflictUpdate(NotesCompanion.insert(day: Value(n.day), body: n.body, updatedAt: n.updatedAt));

  // ---------------- 复盘 ----------------

  ReviewRec review(int day) => _reviews.putIfAbsent(day, () => ReviewRec(day: day));

  ReviewRec? peekReview(int day) => _reviews[day];

  Iterable<ReviewRec> get reviews => _reviews.values;

  void updateReview(int day, void Function(ReviewRec r) change, {bool debounce = true}) {
    final r = review(day);
    change(r);
    r.updatedAt = DateTime.now();
    if (debounce) {
      _debounce('review|$day', () => _saveReview(r));
    } else {
      _saveReview(r);
    }
    notifyListeners();
  }

  void _saveReview(ReviewRec r) {
    _db.into(_db.reviews).insertOnConflictUpdate(ReviewsCompanion.insert(
          day: Value(r.day),
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
    _settings[key] = value;
    _db.into(_db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
    notifyListeners();
  }

  void setFlag(String key, bool on) => setSetting(key, on ? '1' : '0');

  // ---------------- 生成题包 ----------------

  Map<int, GeneratedDayRec> get generatedDays => Map.unmodifiable(_generated);

  /// 调用方必须先用 validateDay 通过质检；这里不再兜底，避免两处规则漂移。
  Future<void> addGeneratedDay(GeneratedDayRec rec) async {
    _generated[rec.day] = rec;
    notifyListeners();
    await _saveGenerated(rec);
  }

  Future<void> _saveGenerated(GeneratedDayRec rec) => _db.into(_db.generatedDays).insertOnConflictUpdate(
        GeneratedDaysCompanion.insert(
          day: Value(rec.day),
          date: rec.payload['date'].toString(),
          theme: rec.payload['theme'].toString(),
          payloadJson: jsonEncode(rec.payload),
          model: Value(rec.model),
          createdAt: rec.createdAt,
        ),
      );

  /// 删除生成的一天及其全部学习记录，避免日后同号新题包继承旧作答。
  Future<void> deleteGeneratedDay(int day) async {
    _generated.remove(day);
    _annotations.removeWhere((a) => a.day == day);
    _notes.remove(day);
    await resetDay(day);
    await (_db.delete(_db.generatedDays)..where((t) => t.day.equals(day))).go();
    await (_db.delete(_db.annotations)..where((t) => t.day.equals(day))).go();
    await (_db.delete(_db.notes)..where((t) => t.day.equals(day))).go();
  }

  // ---------------- 重置与备份 ----------------

  /// 重置本日阅读 / 听力作答、草稿、复盘和展开状态；保留标注与笔记。
  Future<void> resetDay(int day) async {
    _attempts.removeWhere((_, a) => a.day == day);
    _drafts.removeWhere((_, d) => d.day == day);
    _reviews.remove(day);
    final flagKeys = _settings.keys.where((k) => k.startsWith('reveal.$day.')).toList();
    for (final k in flagKeys) {
      _settings.remove(k);
    }
    notifyListeners();
    await (_db.delete(_db.attempts)..where((t) => t.day.equals(day))).go();
    await (_db.delete(_db.drafts)..where((t) => t.day.equals(day))).go();
    await (_db.delete(_db.reviews)..where((t) => t.day.equals(day))).go();
    await (_db.delete(_db.settings)..where((t) => t.key.like('reveal.$day.%'))).go();
  }

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

  /// 按记录合并覆盖，不删除本机已有数据。
  Future<void> importBackup(BackupData data) async {
    await _flushAll();
    for (final g in data.generatedDays) {
      _generated[g.day] = g;
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
      _notes[n.day] = n;
      await _saveNote(n);
    }
    for (final r in data.reviews) {
      _reviews[r.day] = r;
      _saveReview(r);
    }
    for (final a in data.annotations) {
      final existing = _annotations.where((e) => e.identity == a.identity).firstOrNull;
      if (existing != null) {
        updateAnnotation(existing, a.note);
      } else {
        await addAnnotation(a);
      }
    }
    for (final e in data.settings.entries) {
      if (!isSensitiveSettingKey(e.key)) setSetting(e.key, e.value);
    }
    notifyListeners();
  }

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
