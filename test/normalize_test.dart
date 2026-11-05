import 'package:cet6_app/core/spec/normalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('归一化：弯引号转直引号、空白折叠、去首尾空白', () {
    expect(normalizeText('  \u201CHello\u201D,\n  it\u2019s   fine.  '), '"Hello", it\'s fine.');
  });

  test('原文直接包含引文时返回原文区间', () {
    const p = 'First sentence. The cost extends beyond the moment. End.';
    final r = locateRange(p, 'The cost extends beyond the moment.');
    expect(r, isNotNull);
    expect(p.substring(r!.start, r.end), 'The cost extends beyond the moment.');
  });

  test('引号与空白不同也能定位，并映射回原文下标', () {
    const p = 'He said \u201Cwait\u201D  and   left. Then more.';
    final r = locateRange(p, 'He said "wait" and left.');
    expect(r, isNotNull);
    expect(p.substring(r!.start, r.end), 'He said \u201Cwait\u201D  and   left.');
  });

  test('找不到时返回 null', () {
    expect(locateRange('abc def', 'xyz'), isNull);
    expect(locateRange('abc def', '   '), isNull);
  });
}
