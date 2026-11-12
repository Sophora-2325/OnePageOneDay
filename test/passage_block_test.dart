import 'package:cet6_app/app/theme.dart';
import 'package:cet6_app/domain/speech_range.dart';
import 'package:cet6_app/ui/components/passage_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _text = 'Alpha beta gamma';

Widget _host({
  SpeechRange? range,
  ({int start, int end})? locate,
  ValueChanged<int>? onTapAt,
  Brightness brightness = Brightness.light,
}) =>
    MaterialApp(
      theme: buildTheme(brightness),
      home: ProviderScope(
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 240,
              child: PassageBlock(
                paraIndex: 0,
                text: _text,
                showNumber: false,
                speechRange: range,
                locateRange: locate,
                onTapAt: onTapAt,
              ),
            ),
          ),
        ),
      ),
    );

TextSpan _spanFor(WidgetTester tester, String text) {
  final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
  final root = selectable.textSpan!;
  return root.children!.whereType<TextSpan>().firstWhere((s) => s.text == text);
}

void main() {
  testWidgets('不传 onTapAt 时不挂触点监听，正文照常渲染', (tester) async {
    await tester.pumpWidget(_host());
    final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
    final root = selectable.textSpan!;
    expect(root.children, hasLength(1),
        reason: '无标记时 buildMarkedSpans 只返回一个 TextSpan');
    expect((root.children!.single as TextSpan).text, _text);
  });

  testWidgets('选区只在被框定的那一截文字上加蓝底与下划线', (tester) async {
    await tester.pumpWidget(_host(
        range: const SpeechRange(SpeechAnchor(0, 6), SpeechAnchor(0, 10))));
    final root = tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!;
    expect(root.children, hasLength(3));

    final before = root.children!.whereType<TextSpan>().firstWhere((s) => s.text == 'Alpha ');
    final selected = _spanFor(tester, 'beta');
    final after = root.children!.whereType<TextSpan>().firstWhere((s) => s.text == ' gamma');

    expect(before.style?.backgroundColor, isNull);
    expect(after.style?.backgroundColor, isNull);
    expect(selected.style?.backgroundColor, isNotNull);
    expect(selected.style?.decoration, TextDecoration.underline);
  });

  testWidgets('选区与定位引文重叠时，选区样式优先', (tester) async {
    await tester.pumpWidget(_host(
      locate: (start: 0, end: 10),
      range: const SpeechRange(SpeechAnchor(0, 6), SpeechAnchor(0, 10)),
    ));
    final locateOnly = _spanFor(tester, 'Alpha ');
    final overlap = _spanFor(tester, 'beta');
    expect(locateOnly.style?.backgroundColor, isNotNull);
    expect(overlap.style?.backgroundColor, isNot(locateOnly.style?.backgroundColor));
    expect(overlap.style?.decoration, TextDecoration.underline);
  });

  testWidgets('深色主题下选区仍是蓝色系且不透明为 0', (tester) async {
    await tester.pumpWidget(_host(
      brightness: Brightness.dark,
      range: const SpeechRange(SpeechAnchor(0, 6), SpeechAnchor(0, 10)),
    ));
    final style = _spanFor(tester, 'beta').style;
    expect(style?.backgroundColor, isNotNull);
    expect(style!.backgroundColor!.a, greaterThan(0));
    expect(style.backgroundColor!.a, lessThan(1));
  });

  testWidgets('短按提交段内字符下标', (tester) async {
    final offsets = <int>[];
    await tester.pumpWidget(_host(onTapAt: offsets.add));
    final center = tester.getCenter(find.byType(SelectableText));

    final gesture = await tester.startGesture(center);
    await gesture.up();
    await tester.pump();

    expect(offsets, hasLength(1));
    expect(offsets.single, greaterThanOrEqualTo(0));
    expect(offsets.single, lessThanOrEqualTo(_text.length));
  });

  testWidgets('长按选词不会触发朗读定位', (tester) async {
    final offsets = <int>[];
    await tester.pumpWidget(_host(onTapAt: offsets.add));
    final center = tester.getCenter(find.byType(SelectableText));
    // 直接驱动 Listener 回调，精确控制按下与抬起的时间戳。
    final listener = tester
        .widgetList<Listener>(find.byType(Listener))
        .firstWhere((l) => l.onPointerDown != null);

    listener.onPointerDown!(
        PointerDownEvent(position: center, timeStamp: Duration.zero));
    listener.onPointerUp!(PointerUpEvent(
        position: center, timeStamp: const Duration(milliseconds: 500)));
    await tester.pump();

    expect(offsets, isEmpty, reason: '长按选词 / 翻译菜单不能被短按监听抢走');
  });

  testWidgets('拖动（滚动）不会触发朗读定位', (tester) async {
    final offsets = <int>[];
    await tester.pumpWidget(_host(onTapAt: offsets.add));
    final center = tester.getCenter(find.byType(SelectableText));

    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, 40));
    await gesture.up();
    await tester.pump();

    expect(offsets, isEmpty);
  });
}
