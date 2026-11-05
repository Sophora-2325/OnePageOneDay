import 'dart:convert';
import 'dart:io';

import 'package:cet6_app/core/spec/day_model.dart';
import 'package:cet6_app/core/spec/normalize.dart';
import 'package:cet6_app/domain/grading.dart';
import 'package:flutter_test/flutter_test.dart';

/// 内置题库的硬校验：与 tools/validate-days.mjs 的核心规则一致。
void main() {
  final dir = Directory('assets/days');
  final index = (jsonDecode(File('${dir.path}/index.json').readAsStringSync()) as List)
      .map((e) => DayIndexEntry.fromJson((e as Map).cast()))
      .toList();

  test('至少包含 Day 1–7，且天数连续', () {
    expect(index.length, greaterThanOrEqualTo(7));
    for (var i = 0; i < index.length; i++) {
      expect(index[i].day, i + 1);
    }
  });

  for (final entry in index) {
    group('Day ${entry.day}', () {
      final day = DayData.fromJson((jsonDecode(File('${dir.path}/${entry.file}').readAsStringSync()) as Map).cast());

      test('日期与索引一致，2 篇阅读', () {
        expect(day.date, entry.date);
        expect(day.readings.length, 2);
      });

      for (final r in day.readings) {
        test('${r.id}：4–6 段、5 道阅读题 + 4 道听读题、译文段数一致', () {
          expect(r.paragraphs.length, inInclusiveRange(4, 6));
          expect(r.questions.length, 5);
          expect(r.listeningQuestions.length, 4);
          if (r.translation.isNotEmpty) expect(r.translation.length, r.paragraphs.length);
          final words = countWords(r.paragraphs.join(' '));
          expect(words, inInclusiveRange(380, 450));
        });

        test('${r.id}：每题 4 个选项、答案 A–D、定位引文在指定段落中', () {
          for (final q in [...r.questions, ...r.listeningQuestions]) {
            expect(q.options.length, 4, reason: q.id);
            expect(optionLetters.contains(q.answer), isTrue, reason: q.id);
            expect(q.locatePara, inInclusiveRange(1, r.paragraphs.length), reason: q.id);
            expect(
              quoteInParagraph(r.paragraphs[q.locatePara - 1], q.locateQuote),
              isTrue,
              reason: '${r.id} ${q.id} 引文不在第 ${q.locatePara} 段',
            );
          }
        });
      }

      test('翻译 180–200 汉字、采分点 4–6；范文 150–200 词、3 段结构', () {
        expect(countHanzi(day.translation.chinese), inInclusiveRange(180, 200));
        expect(day.translation.scoringPoints.length, inInclusiveRange(4, 6));
        expect(countWords(day.writing.modelEssay), inInclusiveRange(150, 200));
        expect(day.writing.structure.length, 3);
        expect(day.writing.essayParagraphs.length, 3);
        if (day.writing.translation.isNotEmpty) expect(day.writing.translationParagraphs.length, 3);
      });
    });
  }
}
