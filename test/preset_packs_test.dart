// 其余两档预置样张：用 Dart 侧权威校验器按各档规范逐份验，防 JS 构建器与 Dart 规则漂移。
import 'dart:convert';
import 'dart:io';

import 'package:cet6_app/core/spec/day_model.dart';
import 'package:cet6_app/core/spec/validate_day.dart';
import 'package:cet6_app/domain/training_scope.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> readJson(String p) =>
    (jsonDecode(File(p).readAsStringSync()) as Map).cast<String, dynamic>();

void main() {
  for (final goal in [GoalId.cet4, GoalId.kaoyan]) {
    group('${goal.name} 预置样张', () {
      final dir = 'assets/days/${goal.name}';
      final index = (jsonDecode(File('$dir/index.json').readAsStringSync()) as List)
          .map((e) => DayIndexEntry.fromJson((e as Map).cast()))
          .toList();
      final day = readJson('$dir/day-01.json');

      test('索引与题包一致，且通过本档质检', () {
        expect(index, isNotEmpty);
        expect(index.single.day, 1);
        expect(index.single.date, day['date']);
        expect(day['goal'], goal.name);
        final report = validateDay(day, goal: goal);
        expect(report.errors.map((e) => e.message), isEmpty,
            reason: '${goal.name} 未按本档规范通过质检');
      });

      test('错用别的档规范会被质检拦下', () {
        final other = goal == GoalId.cet4 ? GoalId.kaoyan : GoalId.cet4;
        // 字数区间不同，至少词数规则会报错；证明规则确实按档生效。
        final report = validateDay(day, goal: other);
        expect(report.ok, isFalse);
      });

      test('DayData 可以解析，题目与译文齐全', () {
        final data = DayData.fromJson(day);
        expect(data.day, 1);
        expect(data.readings.length, 2);
        for (final r in data.readings) {
          expect(r.questions.length, 5);
          expect(r.listeningQuestions.length, 4);
          expect(r.translation.length, r.paragraphs.length);
        }
      });
    });
  }

  test('三档预置天数与随包目录一致', () {
    for (final g in kGoals) {
      final dir = g.id == GoalId.cet6 ? 'assets/days' : 'assets/days/${g.id.name}';
      final index = (jsonDecode(File('$dir/index.json').readAsStringSync()) as List).length;
      expect(index, g.presetDays, reason: '${g.name} 的 presetDays 与实际题库不符');
    }
  });

  test('已下线两档的随包目录、assets 声明与语料均已移除', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final corpus = File('tools/goal_corpus.mjs').readAsStringSync();
    final packs = File('tools/build_goal_packs.mjs').readAsStringSync();
    for (final name in ['tem4', 'tem8']) {
      expect(Directory('assets/days/$name').existsSync(), isFalse, reason: '$name 目录仍存在');
      expect(pubspec, isNot(contains('assets/days/$name/')));
      expect(corpus, isNot(contains('$name:')));
      expect(packs, isNot(contains('$name:')));
    }
  });
}
