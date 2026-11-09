import 'package:cet6_app/domain/phonetic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const four = '本句含义：数量可观。\n词性与作用：形容词。\n用法说明：搭配 increase。\n原句翻译：收益可观。';

  test('正常音标首行被剥离，四项原样保留', () {
    final r = parsePhonetic('音标：/səbˈstænʃəl/\n$four');
    expect(r.phonetic, 'səbˈstænʃəl');
    expect(r.body, four);
  });

  test('半角冒号、空格、CRLF 都能识别', () {
    final r = parsePhonetic('  音标 : /wɜːd/  \r\n$four');
    expect(r.phonetic, 'wɜːd');
    expect(r.body, four);
  });

  test('Markdown 包裹不污染正文', () {
    final r = parsePhonetic('**音标：/wɜːd/**\n$four');
    expect(r.phonetic, 'wɜːd');
    expect(r.body, four);
  });

  test('短语 / 不确定时回落 /—/，正文照常', () {
    final r = parsePhonetic('音标：/—/\n$four');
    expect(r.phonetic, '—');
    expect(r.body, four);
    expect(parsePhonetic('音标：/-/').phonetic, '—');
  });

  test('模型没给音标行时整段都是正文', () {
    final r = parsePhonetic(four);
    expect(r.phonetic, '—');
    expect(r.body, four);
  });

  test('有音标标签但缺 /.../ 时不丢信息', () {
    final r = parsePhonetic('音标：暂时无法确认\n$four');
    expect(r.phonetic, '—');
    expect(r.body, '暂时无法确认\n$four');
  });

  test('音标行尾部多余说明并入正文', () {
    final r = parsePhonetic('音标：/wɜːd/（英式）\n$four');
    expect(r.phonetic, 'wɜːd');
    expect(r.body, '（英式）\n$four');
  });

  test('空串不报错', () {
    final r = parsePhonetic('  \n ');
    expect(r.phonetic, '—');
    expect(r.body, '');
  });

  test('只有音标行时正文为空', () {
    final r = parsePhonetic('音标：/wɜːd/');
    expect(r.phonetic, 'wɜːd');
    expect(r.body, '');
  });
}
