import 'dart:convert';
import 'dart:io';

import 'package:cet6_app/core/spec/validate_day.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> loadDay(int n) =>
    (jsonDecode(File('assets/days/day-${n.toString().padLeft(2, '0')}.json').readAsStringSync()) as Map)
        .cast<String, dynamic>();

/// 深拷贝后再改，避免用例之间互相污染。
Map<String, dynamic> mutate(void Function(Map<String, dynamic> d) change) {
  final d = (jsonDecode(jsonEncode(loadDay(7))) as Map).cast<String, dynamic>();
  change(d);
  return d;
}

Map<String, dynamic> r1(Map<String, dynamic> d) => (d['readings'] as List)[0] as Map<String, dynamic>;

List<String> errorsOf(Map<String, dynamic> d) => validateDay(d).errors.map((e) => e.message).toList();

void main() {
  group('golden：Node 校验器全绿的 Day 1–7，Dart 校验器也必须 0 错误', () {
    for (var n = 1; n <= 7; n++) {
      test('Day $n', () {
        final report = validateDay(loadDay(n));
        expect(report.errors.map((e) => e.message), isEmpty);
      });
    }
  });

  group('变异：每条规则单独破坏后，报错文案与 validate-days.mjs 一致', () {
    test('定位引文被改写', () {
      final d = mutate((d) => (r1(d)['questions'] as List)[2]['locate']['quote'] = 'This sentence never appears in the passage at all.');
      expect(errorsOf(d), ['Day 7 / reading 1 / q3: locate.quote is not a verbatim substring of paragraph ${r1(d)['questions'][2]['locate']['para']}']);
      expect(validateDay(d).failedParts, {'r1'});
    });

    test('引文跨段 → 段号越界', () {
      final d = mutate((d) => (r1(d)['questions'] as List)[0]['locate']['para'] = 9);
      expect(errorsOf(d).single, startsWith('Day 7 / reading 1 / q1: locate.para 9 out of range 1-'));
    });

    test('弯引号与多余空白不影响定位（归一化逐字一致）', () {
      final d = mutate((d) {
        final q = (r1(d)['questions'] as List)[0];
        q['locate']['quote'] = '  ${(q['locate']['quote'] as String).replaceAll(' ', '   ')}  ';
      });
      expect(errorsOf(d), isEmpty);
    });

    test('题量、选项、答案、解析', () {
      final d = mutate((d) {
        final qs = r1(d)['questions'] as List;
        qs[0]['options'] = ['a', 'b', 'c'];
        qs[1]['answer'] = 'E';
        qs[2]['explain'] = '太短';
        (r1(d)['listeningQuestions'] as List).removeLast();
      });
      expect(errorsOf(d), [
        'Day 7 / reading 1 / q1: expected 4 options, got 3',
        'Day 7 / reading 1 / q2: answer must be A-D, got E',
        'Day 7 / reading 1 / q3: explanation too short',
        'Day 7 / reading 1 / listening: expected 4 questions, got 3',
      ]);
    });

    test('听读题题干与阅读题重复', () {
      final d = mutate((d) => (r1(d)['listeningQuestions'] as List)[0]['stem'] = (r1(d)['questions'] as List)[0]['stem']);
      expect(errorsOf(d), ['Day 7 / reading 1: listening question duplicates a reading stem']);
    });

    test('段数与词数', () {
      final d = mutate((d) => r1(d)['paragraphs'] = List.filled(3, 'too short'));
      expect(errorsOf(d), contains('Day 7 / reading 1: expected 4-6 paragraphs, got 3'));
      final d2 = mutate((d) => (r1(d)['paragraphs'] as List).add(List.filled(80, 'extra').join(' ')));
      expect(errorsOf(d2).first, matches(RegExp(r'^Day 7 / reading 1: \d+ words, expected 380-450$')));
    });

    test('译文段数不一致', () {
      final d = mutate((d) => (r1(d)['translation'] as List).removeLast());
      expect(errorsOf(d).single, startsWith('Day 7 / translations: r1 should have'));
      final d2 = mutate((d) => d['writing']['translation'] = '只有一段的范文译文，没有空行分隔开来的三段结构。');
      expect(errorsOf(d2), ['Day 7 / translations: writing translation should have 3 paragraphs']);
    });

    test('翻译题：汉字数、采分点、参考译文', () {
      final d = mutate((d) {
        d['translation']['chinese'] = '太短了';
        d['translation']['scoringPoints'] = [
          {'zh': '一', 'en': ''},
        ];
      });
      expect(errorsOf(d), [
        'Day 7 / translation: 3 Chinese characters, expected 180-200',
        'Day 7 / translation: expected 4-6 scoring points',
      ]);
      expect(validateDay(d).failedParts, {'translation'});
    });

    test('写作：范文词数、structure、expressions', () {
      final d = mutate((d) {
        d['writing']['structure'] = ['一', '二'];
        d['writing']['expressions'] = ['x'];
      });
      expect(errorsOf(d), [
        'Day 7 / writing: expected 3 structure paragraphs',
        'Day 7 / writing: expected at least 5 expressions',
      ]);
    });

    test('模型产出类型错乱也不会崩溃，只会报错', () {
      final report = validateDay({
        'day': '8',
        'date': 'tomorrow',
        'readings': [
          {'id': 'r1', 'paragraphs': 'not a list'},
          42,
        ],
        'translation': [],
        'writing': null,
      });
      expect(report.ok, isFalse);
      expect(report.errors.map((e) => e.message), containsAll([
        'Day 8: invalid day number',
        'Day 8: invalid date',
        'Day 8: invalid week',
        'Day 8: missing theme',
        'Day 8 / reading 1: expected 4-6 paragraphs, got none',
        'Day 8 / reading 2: missing object',
        'Day 8 / translation: missing object',
        'Day 8 / writing: missing object',
      ]));
    });
  });

  test('分段校验：单篇阅读、翻译、写作各自独立', () {
    final d = loadDay(7);
    expect(validateReadingPart(r1(d), dayNo: 7, index: 0).ok, isTrue);
    expect(validateTranslationPart((d['translation'] as Map).cast(), dayNo: 7).ok, isTrue);
    expect(validateWritingPart((d['writing'] as Map).cast(), dayNo: 7).ok, isTrue);
  });
}
