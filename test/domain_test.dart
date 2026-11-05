import 'package:cet6_app/core/spec/day_model.dart';
import 'package:cet6_app/domain/day_summary.dart';
import 'package:cet6_app/domain/grading.dart';
import 'package:cet6_app/ui/components/highlight_spans.dart';
import 'package:flutter/painting.dart';
import 'package:cet6_app/domain/sentence.dart';
import 'package:flutter_test/flutter_test.dart';

Question q(String id, String answer) => Question(
      id: id,
      type: '细节题',
      stem: 's',
      options: const ['a', 'b', 'c', 'd'],
      answer: answer,
      locatePara: 1,
      locateQuote: 'x',
      explain: 'e',
    );

void main() {
  test('判分：正确数、总数与错题', () {
    final qs = [q('q1', 'A'), q('q2', 'B'), q('q3', 'C')];
    final g = grade(qs, {'q1': 'A', 'q2': 'C'});
    expect(g.correct, 1);
    expect(g.total, 3);
    expect(g.wrongIds, ['q2', 'q3']);
    expect(allAnswered(qs, {'q1': 'A', 'q2': 'C'}), isFalse);
  });

  test('词数与汉字数口径', () {
    expect(countWords('  A well-known  fact,\nreally. '), 4);
    expect(countWords(''), 0);
    expect(countHanzi('中国茶文化 tea 123，'), 5);
  });

  test('默认训练日：当天 > 不晚于今天的最后一天 > 第一天', () {
    final days = [
      const DayIndexEntry(day: 1, date: '2026-10-31', week: 1, theme: '', file: ''),
      const DayIndexEntry(day: 2, date: '2026-11-01', week: 1, theme: '', file: ''),
      const DayIndexEntry(day: 3, date: '2026-11-02', week: 1, theme: '', file: ''),
    ];
    expect(pickDefaultDay(days, DateTime(2026, 11, 1)), 2);
    expect(pickDefaultDay(days, DateTime(2026, 12, 1)), 3);
    expect(pickDefaultDay(days, DateTime(2026, 10, 1)), 1);
  });

  test('连续完成天数从最近完成日往前数', () {
    expect(completionStreak([1, 2, 3, 4, 5], {2, 3, 4}), 3);
    expect(completionStreak([1, 2, 3], {1, 3}), 1);
    expect(completionStreak([1, 2, 3], {}), 0);
  });

  test('高亮切分：重叠区间合并样式，文本无损', () {
    const text = 'abcdefghij';
    final spans = buildMarkedSpans(text, const [
      SpanMark(2, 6, TextStyle(fontWeight: FontWeight.bold)),
      SpanMark(4, 8, TextStyle(fontStyle: FontStyle.italic)),
    ]);
    expect(spans.map((s) => s.text).join(), text);
    final both = spans.firstWhere((s) => s.text == 'ef');
    expect(both.style?.fontWeight, FontWeight.bold);
    expect(both.style?.fontStyle, FontStyle.italic);
  });

  test('选词翻译只取所在原句', () {
    const text = 'First sentence here. The team rewards stars, not helpers. Last one!';
    final at = text.indexOf('rewards');
    final s = sentenceAround(text, at, at + 'rewards'.length);
    expect(s.before, 'The team ');
    expect(s.word, 'rewards');
    expect(s.after, ' stars, not helpers.');
    final first = sentenceAround(text, 0, 5);
    expect('${first.before}${first.word}${first.after}', 'First sentence here.');
  });
}
