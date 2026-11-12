import 'package:cet6_app/domain/speech_range.dart';
import 'package:flutter_test/flutter_test.dart';

const _paras = ['Alpha beta gamma', 'Delta epsilon zeta', 'Eta theta iota'];

void main() {
  group('expandRange', () {
    test('整听：从段中锚点展开到文末', () {
      final chunks = expandRange(
          _paras, SpeechRange(const SpeechAnchor(0, 6), articleEnd(_paras)));
      expect(chunks.map((c) => c.text),
          ['beta gamma', 'Delta epsilon zeta', 'Eta theta iota']);
      expect(chunks.map((c) => c.para), [0, 1, 2]);
      expect(chunks.first.start, 6);
      expect(chunks.first.end, _paras[0].length);
    });

    test('精读：跨段时首段切片、中间整段、末段切片', () {
      final chunks = expandRange(
          _paras, const SpeechRange(SpeechAnchor(0, 6), SpeechAnchor(2, 4)));
      expect(chunks.map((c) => c.text), ['beta gamma', 'Delta epsilon zeta', 'Eta']);
      expect(chunks.last.end, 4);
    });

    test('终点在起点之前时自动交换', () {
      final forward = expandRange(
          _paras, const SpeechRange(SpeechAnchor(0, 6), SpeechAnchor(2, 4)));
      final backward = expandRange(
          _paras, const SpeechRange(SpeechAnchor(2, 4), SpeechAnchor(0, 6)));
      expect(backward, forward);
    });

    test('同一段内的区间只产生一个切片', () {
      final chunks = expandRange(
          _paras, const SpeechRange(SpeechAnchor(1, 6), SpeechAnchor(1, 14)));
      expect(chunks, hasLength(1));
      expect(chunks.single.text, 'epsilon');
      expect(chunks.single.para, 1);
    });

    test('空段跳过，越界偏移钳制到段长', () {
      final chunks = expandRange(
        ['', 'A B', ''],
        const SpeechRange(SpeechAnchor(0, 999), SpeechAnchor(2, 999)),
      );
      expect(chunks.map((c) => c.text), ['A B']);
      expect(chunks.single.end, 3);
    });

    test('空切片不产生 chunk', () {
      final chunks = expandRange(
          _paras, const SpeechRange(SpeechAnchor(1, 3), SpeechAnchor(1, 3)));
      expect(chunks, isEmpty);
    });

    test('空文章返回空队列', () {
      expect(
          expandRange(const <String>[],
              const SpeechRange(SpeechAnchor(0, 0), SpeechAnchor(0, 0))),
          isEmpty);
    });
  });

  group('localRange', () {
    const range = SpeechRange(SpeechAnchor(0, 6), SpeechAnchor(2, 4));

    test('首段只染起点之后', () {
      final r = localRange(range, 0, _paras[0]);
      expect(r, (start: 6, end: _paras[0].length));
    });

    test('中间段整段', () {
      final r = localRange(range, 1, _paras[1]);
      expect(r, (start: 0, end: _paras[1].length));
    });

    test('末段只染终点之前', () {
      expect(localRange(range, 2, _paras[2]), (start: 0, end: 4));
    });

    test('区间外的段返回 null，null 区间返回 null', () {
      expect(localRange(null, 0, _paras[0]), isNull);
      expect(
          localRange(const SpeechRange(SpeechAnchor(1, 2), SpeechAnchor(1, 5)),
              0, _paras[0]),
          isNull);
    });
  });

  group('词边界吸附', () {
    test('点在词中间回退到词首', () {
      expect(snapToWordStart('Alpha beta', 8), 6);
    });

    test("缩写 don't 不被从中间切断", () {
      expect(snapToWordStart("Don't stop here", 2), 0);
      expect(snapToWordEnd("Don't stop here", 2), 5);
    });

    test('连字符词 well-known 是一个整体', () {
      expect(snapToWordStart('a well-known fact', 8), 2);
      expect(snapToWordEnd('a well-known fact', 8), 12);
    });

    test('句点：U.S 后面的句末点不并进词里', () {
      expect(snapToWordEnd('U.S. policy', 2), 3);
    });

    test('数字与小数点', () {
      expect(snapToWordStart('rate 3.5 times', 6), 5);
      expect(snapToWordEnd('rate 3.5 times', 6), 8);
    });

    test('点在空白上向后吸到最近词首', () {
      expect(snapToWordStart('one two', 3), 4);
    });

    test('段尾吸到最后一个词首', () {
      expect(snapToWordStart('one two', 7), 4);
      expect(snapToWordEnd('one two', 7), 7);
    });

    test('空串与越界不抛异常', () {
      expect(snapToWordStart('', 3), 0);
      expect(snapToWordEnd('', 3), 0);
      expect(snapToWordStart('abc', 999), 0);
      expect(snapToWordEnd('abc', 999), 3);
    });

    test('中文段落不误判为英文词', () {
      expect(snapToWordStart('中文测试', 2), 4);
    });
  });

  group('SpeechRange / SpeechAnchor', () {
    test('锚点按段再按偏移排序', () {
      expect(const SpeechAnchor(0, 9).compareTo(const SpeechAnchor(1, 0)),
          lessThan(0));
      expect(const SpeechAnchor(2, 1).compareTo(const SpeechAnchor(2, 0)),
          greaterThan(0));
    });

    test('ordered 只在倒序时交换', () {
      const r = SpeechRange(SpeechAnchor(2, 4), SpeechAnchor(0, 6));
      expect(r.ordered.start, const SpeechAnchor(0, 6));
      const ok = SpeechRange(SpeechAnchor(0, 1), SpeechAnchor(0, 5));
      expect(ok.ordered.start, const SpeechAnchor(0, 1));
    });

    test('articleEnd 取最后一段末尾', () {
      expect(articleEnd(_paras), SpeechAnchor(2, _paras[2].length));
      expect(articleEnd(const <String>[]), const SpeechAnchor(0, 0));
    });
  });
}
