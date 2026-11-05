import 'dart:convert';
import 'dart:io';

import 'package:cet6_app/core/backup/backup_codec.dart';
import 'package:cet6_app/core/storage/app_store.dart';
import 'package:cet6_app/core/storage/db.dart';
import 'package:cet6_app/core/storage/records.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

BackupData sample() => BackupData(
      attempts: [
        AttemptRec(day: 7, kind: 'reading', readingId: 'r1', answers: {'q1': 'C'}, submitted: true, score: 4, total: 5),
      ],
      drafts: [DraftRec(day: 7, kind: 'writing', body: 'Play matters.')],
      annotations: [
        AnnotationRec(day: 7, target: 'r1', paraIndex: 1, start: 4, end: 10, quote: 'reward', note: '奖励'),
      ],
      notes: [NoteRec(day: 7, body: '今天的笔记')],
      reviews: [ReviewRec(day: 7, wrongReason: '定位慢', scoring: {0, 2}, done: true)],
      settings: {'themeMode': 'dark', 'apiKey': 'sk-secret', 'baseUrl': 'https://x', 'authToken': 't'},
    );

void main() {
  test('备份往返：字段完整，凭据类设置被剔除', () {
    final json = jsonEncode(sample().toJson());
    expect(json.contains('sk-secret'), isFalse);
    expect(json.contains('https://x'), isFalse);

    final back = BackupData.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(back.attempts.single.answers['q1'], 'C');
    expect(back.attempts.single.score, 4);
    expect(back.drafts.single.body, 'Play matters.');
    expect(back.annotations.single.note, '奖励');
    expect(back.notes.single.body, '今天的笔记');
    expect(back.reviews.single.scoring, {0, 2});
    expect(back.reviews.single.done, isTrue);
    expect(back.settings, {'themeMode': 'dark'});
    expect(back.days, {7});
  });

  test('schema 不匹配时拒绝导入', () {
    expect(() => BackupData.fromJson({'schema': 'other'}), throwsFormatException);
  });

  group('AppStore（内存 SQLite）', () {
    late AppDatabase db;
    late AppStore store;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      store = AppStore(db);
      await store.load();
    });

    tearDown(() => db.close());

    test('作答、提交、重做写入数据库并可重新读出', () async {
      store.answer(7, 'reading', 'r1', 'q1', 'B');
      store.submit(7, 'reading', 'r1', score: 3, total: 5);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final reloaded = AppStore(db);
      await reloaded.load();
      final a = reloaded.peekAttempt(7, 'reading', 'r1')!;
      expect(a.answers['q1'], 'B');
      expect(a.submitted, isTrue);
      expect(a.score, 3);
    });

    test('重置本日保留标注和笔记', () async {
      store.answer(7, 'reading', 'r1', 'q1', 'B');
      store.setDraft(7, 'translation', 'draft');
      store.setNote(7, 'note');
      await store.flushNote(7);
      await store.addAnnotation(AnnotationRec(day: 7, target: 'r1', paraIndex: 0, start: 0, end: 3, quote: 'The', note: 'n'));
      store.setFlag('reveal.7.translation', true);

      await store.resetDay(7);
      expect(store.peekAttempt(7, 'reading', 'r1'), isNull);
      expect(store.draft(7, 'translation'), '');
      expect(store.flag('reveal.7.translation'), isFalse);
      expect(store.note(7), 'note');
      expect(store.annotationsFor(7).length, 1);
    });

    test('导入按记录合并，不删除本机已有数据；同一处标注不重复', () async {
      store.setNote(6, '第六天');
      await store.flushNote(6);
      final data = sample();
      await store.importBackup(data);
      await store.importBackup(data);

      expect(store.note(6), '第六天');
      expect(store.note(7), '今天的笔记');
      expect(store.peekAttempt(7, 'reading', 'r1')!.score, 4);
      expect(store.annotationsFor(7).length, 1);
      expect(store.setting('themeMode'), 'dark');
      expect(store.setting('apiKey'), isNull);
    });

    test('生成题包：落库可重读；删除时连带清掉该日学习记录', () async {
      await store.addGeneratedDay(GeneratedDayRec(day: 8, payload: generatedDay(8), model: 'm'));
      store.answer(8, 'reading', 'r1', 'q1', 'A');
      store.setNote(8, 'n');
      await store.flushNote(8);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      var reloaded = AppStore(db);
      await reloaded.load();
      expect(reloaded.generatedDays[8]!.theme, generatedDay(8)['theme']);

      await store.deleteGeneratedDay(8);
      reloaded = AppStore(db);
      await reloaded.load();
      expect(reloaded.generatedDays, isEmpty);
      expect(reloaded.peekAttempt(8, 'reading', 'r1'), isNull);
      expect(reloaded.note(8), '');
    });
  });

  group('备份中的生成题包', () {
    test('往返保留；导入时重新过质检，坏题包被丢弃并计数', () {
      final bad = generatedDay(9);
      ((bad['readings'] as List)[0]['questions'] as List)[0]['locate']['quote'] = 'Not in the passage at all, invented.';
      final data = BackupData(
        attempts: const [],
        drafts: const [],
        annotations: const [],
        notes: const [],
        reviews: const [],
        settings: const {},
        generatedDays: [
          GeneratedDayRec(day: 8, payload: generatedDay(8)),
          GeneratedDayRec(day: 9, payload: bad),
        ],
      );
      final back = BackupData.fromJson(jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>);
      expect(back.generatedDays.map((e) => e.day), [8]);
      expect(back.rejectedGeneratedDays, 1);
      expect(back.summary(), contains('1 天题包未通过质检'));
    });
  });
}

/// 用预置 Day 7 改号模拟一份已过质检的生成题包。
Map<String, dynamic> generatedDay(int n) {
  final d = (jsonDecode(File('assets/days/day-07.json').readAsStringSync()) as Map).cast<String, dynamic>();
  return d
    ..['day'] = n
    ..['date'] = '2026-11-${n.toString().padLeft(2, '0')}';
}
