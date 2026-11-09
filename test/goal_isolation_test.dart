// v3 回归：三档进度隔离、备份 v2、分档质检与分档 prompt。
import 'dart:convert';
import 'dart:io';

import 'package:cet6_app/core/backup/backup_codec.dart';
import 'package:cet6_app/core/spec/prompt.dart';
import 'package:cet6_app/core/spec/validate_day.dart';
import 'package:cet6_app/core/storage/app_store.dart';
import 'package:cet6_app/core/storage/db.dart';
import 'package:cet6_app/core/storage/records.dart';
import 'package:cet6_app/domain/day_summary.dart';
import 'package:cet6_app/domain/training_scope.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> loadDay(int n) =>
    (jsonDecode(File('assets/days/day-${n.toString().padLeft(2, '0')}.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();

void switchGoal(AppStore store, GoalId goal) =>
    store.setSetting(TrainingScope.keyGoal, goal.name);

void main() {
  group('三档进度隔离（内存 SQLite）', () {
    late AppDatabase db;
    late AppStore store;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      store = AppStore(db);
      await store.load();
    });

    tearDown(() => db.close());

    test('同一日号下各档作答 / 草稿 / 笔记 / 复盘互不串，切回来原样恢复', () async {
      switchGoal(store, GoalId.cet6);
      store.answer(3, 'reading', 'r1', 'q1', 'A');
      store.submit(3, 'reading', 'r1', score: 4, total: 5);
      store.setDraft(3, 'translation', '六级草稿');
      store.setNote(3, '六级笔记');
      store.updateReview(3, (r) => r.wrongReason = '六级错因', debounce: false);
      await store.flushNote(3);
      await store.addAnnotation(AnnotationRec(
          day: 3, target: 'r1', paraIndex: 0, start: 0, end: 4, quote: 'From', note: '六级标注'));

      switchGoal(store, GoalId.cet4);
      expect(store.peekAttempt(3, 'reading', 'r1'), isNull);
      expect(store.draft(3, 'translation'), '');
      expect(store.note(3), '');
      expect(store.peekReview(3), isNull);
      expect(store.annotationsFor(3), isEmpty);

      store.answer(3, 'reading', 'r1', 'q1', 'C');
      store.setDraft(3, 'translation', '四级草稿');
      store.setNote(3, '四级笔记');
      await store.flushNote(3);
      await store.addAnnotation(AnnotationRec(
          day: 3, target: 'r1', paraIndex: 0, start: 0, end: 4, quote: 'From', note: '四级标注'));

      expect(store.peekAttempt(3, 'reading', 'r1')!.answers['q1'], 'C');
      expect(store.annotationsFor(3).single.note, '四级标注');

      switchGoal(store, GoalId.cet6);
      expect(store.peekAttempt(3, 'reading', 'r1')!.answers['q1'], 'A');
      expect(store.peekAttempt(3, 'reading', 'r1')!.score, 4);
      expect(store.draft(3, 'translation'), '六级草稿');
      expect(store.note(3), '六级笔记');
      expect(store.peekReview(3)!.wrongReason, '六级错因');
      expect(store.annotationsFor(3).single.note, '六级标注');

      // 落库后重开 App：两档都还在，且没有互相覆盖。
      await store.flush();
      final reloaded = AppStore(db);
      await reloaded.load();
      switchGoal(reloaded, GoalId.cet4);
      expect(reloaded.draft(3, 'translation'), '四级草稿');
      expect(reloaded.note(3), '四级笔记');
      switchGoal(reloaded, GoalId.cet6);
      expect(reloaded.draft(3, 'translation'), '六级草稿');
      expect(reloaded.note(3), '六级笔记');
    });

    test('生成题包按档隔离；删除一档的 Day 8 不影响另一档', () async {
      switchGoal(store, GoalId.cet6);
      final cet6Pack = loadDay(7)..['day'] = 8;
      await store.addGeneratedDay(GeneratedDayRec(day: 8, payload: cet6Pack));
      store.answer(8, 'reading', 'r1', 'q1', 'B');

      switchGoal(store, GoalId.kaoyan);
      final otherPack = loadDay(7)..['day'] = 8;
      await store.addGeneratedDay(GeneratedDayRec(day: 8, payload: otherPack));
      expect(store.generatedDays[8], isNotNull);
      expect(store.peekAttempt(8, 'reading', 'r1'), isNull);

      await store.deleteGeneratedDay(8);
      expect(store.generatedDays[8], isNull);
      switchGoal(store, GoalId.cet6);
      expect(store.generatedDays[8], isNotNull);
      expect(store.peekAttempt(8, 'reading', 'r1')!.answers['q1'], 'B');
    });

    test('resetDay 只清当前档本日；DaySummary 可按档只读统计', () async {
      switchGoal(store, GoalId.cet6);
      store.answer(2, 'reading', 'r1', 'q1', 'A');
      store.submit(2, 'reading', 'r1', score: 5, total: 5);
      store.setFlag(store.revealKey(2, 'translation'), true);
      switchGoal(store, GoalId.kaoyan);
      store.answer(2, 'reading', 'r1', 'q1', 'D');
      store.submit(2, 'reading', 'r1', score: 1, total: 5);

      expect(DaySummary.of(store, 2).readingScore, 1);
      expect(DaySummary.of(store, 2, goal: GoalId.cet6).readingScore, 5);

      await store.resetDay(2);
      expect(DaySummary.of(store, 2).readingScore, 0);
      expect(DaySummary.of(store, 2, goal: GoalId.cet6).readingScore, 5);
      switchGoal(store, GoalId.cet6);
      expect(store.flag(store.revealKey(2, 'translation')), isTrue);
    });

    test('1.0 旧数据（day 1..7 无目标）自动归入六级', () async {
      // 直接用底层表写入旧格式，模拟升级上来的数据库。
      await db.into(db.notes).insert(NotesCompanion.insert(
          day: const Value(5), body: '老版本笔记', updatedAt: DateTime.now()));
      final reloaded = AppStore(db);
      await reloaded.load();
      switchGoal(reloaded, GoalId.cet6);
      expect(reloaded.note(5), '老版本笔记');
      switchGoal(reloaded, GoalId.cet4);
      expect(reloaded.note(5), '');
    });
  });

  group('备份 schema v2', () {
    test('跨档往返：goal 显式保留、按档分组、凭据仍被剔除', () {
      final data = BackupData(
        attempts: [
          AttemptRec(goal: GoalId.cet6, day: 1, kind: 'reading', readingId: 'r1'),
          AttemptRec(goal: GoalId.cet4, day: 1, kind: 'reading', readingId: 'r1'),
        ],
        drafts: const [],
        annotations: const [],
        notes: [NoteRec(goal: GoalId.kaoyan, day: 2, body: '考研笔记')],
        reviews: const [],
        settings: {'themeMode': 'dark', 'apiKey': 'sk-do-not-export'},
      );
      final json = jsonEncode(data.toJson());
      expect(json.contains('sk-do-not-export'), isFalse);
      final back = BackupData.fromJson(jsonDecode(json) as Map<String, dynamic>);
      expect(back.attempts.map((e) => e.goal), [GoalId.cet6, GoalId.cet4]);
      expect(back.daysByGoal.keys.toSet(), {GoalId.cet6, GoalId.cet4, GoalId.kaoyan});
      expect(back.summary(), contains('六级 1 天'));
      expect(back.summary(), contains('四级 1 天'));
    });

    test('1.0 的 v1 备份可以导入，全部归入六级', () {
      final v1 = {
        'schema': legacyBackupSchema,
        'exportedAt': '2026-11-01T10:00:00.000',
        'appVersion': '1.0.0',
        'state': {
          'attempts': [
            {
              'day': 7,
              'kind': 'reading',
              'readingId': 'r1',
              'answers': {'q1': 'B'},
              'submitted': true,
              'score': 3,
              'total': 5,
              'updatedAt': '2026-11-01T10:00:00.000'
            }
          ],
          'drafts': [],
          'annotations': [],
          'notes': [],
          'reviews': [],
          'settings': {'themeMode': 'light'},
        },
        'generatedDays': [],
      };
      final back = BackupData.fromJson(v1);
      expect(back.attempts.single.goal, GoalId.cet6);
      expect(back.attempts.single.answers['q1'], 'B');
      expect(back.daysByGoal.keys, [GoalId.cet6]);
    });

    test('未知 schema 仍然拒绝导入', () {
      expect(() => BackupData.fromJson({'schema': 'cet6.backup.v0'}), throwsFormatException);
    });
  });

  group('分档规范', () {
    test('同一份题包按不同档的字数规则得出不同结论', () {
      final day = loadDay(7); // 六级 414 词，正好超出四级上限
      expect(validateDay(day).ok, isTrue);
      final asCet4 = {...day, 'goal': GoalId.cet4.name};
      final errors = validateDay(asCet4).errors.map((e) => e.message).toList();
      expect(errors.any((e) => e.contains('expected 290-350')), isTrue);
      expect(validateDay(asCet4, goal: GoalId.cet6).ok, isTrue);
    });

    test('system prompt 与阅读 prompt 按档注入考试名与主题池', () {
      expect(systemPromptFor(GoalId.cet4), contains('CET-4'));
      expect(systemPromptFor(GoalId.cet6), contains('CET-6'));
      final day = loadDay(7);
      final p = readingPrompt(
        id: 'r1',
        dayNo: 1,
        example: (day['readings'] as List)[0] as Map<String, dynamic>,
        avoidTitles: const [],
        goal: GoalId.kaoyan,
      );
      expect(p, contains('考研英语'));
      expect(p, contains('长难句'));
      expect(p, contains('id = "r1"'));
      expect(translationPrompt(
        example: (day['translation'] as Map).cast(),
        topic: '科技',
        goal: GoalId.cet4,
      ), contains('130–160'));
    });

    test('三档都有完整的材料规范与预置样张', () {
      for (final g in kGoals) {
        expect(g.ready, isTrue);
        expect(g.presetDays, greaterThan(0));
        expect(g.rule.minWords, lessThan(g.rule.maxWords));
        expect(g.rule.topics, isNotEmpty);
        expect(g.rule.questionRule, isNotEmpty);
      }
    });
  });
}
