import 'package:cet6_app/app/theme.dart';
import 'package:cet6_app/domain/speech_range.dart';
import 'package:cet6_app/features/reading_mode/reading_aloud.dart';
import 'package:cet6_app/features/reading_mode/reading_mode_page.dart';
import 'package:cet6_app/features/reading_mode/speech_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  ReadingAloud aloud, {
  SpeechMode mode = SpeechMode.whole,
  MarkPhase phase = MarkPhase.idle,
  VoidCallback? onStart,
  VoidCallback? onEnd,
  VoidCallback? onClear,
}) =>
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        bottomNavigationBar: ListeningBar(
          aloud: aloud,
          sourceKey: 'x',
          mode: mode,
          markPhase: phase,
          onStart: onStart ?? () {},
          onEnd: onEnd ?? () {},
          onClearRange: onClear ?? () {},
        ),
      ),
    );

GestureDetector _tapTarget(WidgetTester tester, String label) => tester
    .widget<GestureDetector>(find
        .ancestor(
          of: find.text(label),
          matching: find.byType(GestureDetector),
        )
        .first);

void main() {
  testWidgets('倍速值点击就地输入，2.0 自动收敛到 1.25', (tester) async {
    final aloud = ReadingAloud();
    await tester.pumpWidget(_host(aloud));

    expect(find.text('1.00x'), findsOneWidget);
    await tester.tap(find.text('1.00x'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2.0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(aloud.rate, 1.25);
    expect(find.text('1.25x'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('0.5 收敛到 0.75，非法输入保留上一档', (tester) async {
    final aloud = ReadingAloud();
    await tester.pumpWidget(_host(aloud));

    await tester.tap(find.text('1.00x'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(aloud.rate, 0.75);

    await tester.tap(find.text('0.75x'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(aloud.rate, 0.75);
    expect(find.text('0.75x'), findsOneWidget);
  });

  testWidgets('滑块拖动只更新显示，松手才提交给朗读控制器', (tester) async {
    final aloud = ReadingAloud();
    await tester.pumpWidget(_host(aloud));

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(0.9);
    await tester.pump();
    expect(find.text('0.90x'), findsOneWidget);
    expect(aloud.rate, 1.0, reason: '拖动中不应调用 setRate，避免反复重启当前段');

    slider.onChangeEnd!(0.9);
    await tester.pump();
    expect(aloud.rate, 0.9);
    expect(find.text('0.90x'), findsOneWidget);
  });

  testWidgets('整听不显示精读按钮，精读显示三个操作与状态', (tester) async {
    final aloud = ReadingAloud(engine: FakeSpeechEngine());
    await tester.pumpWidget(_host(aloud));
    expect(find.text('开始'), findsNothing);
    expect(find.text('结束'), findsNothing);
    expect(find.text('清除范围'), findsNothing);
    expect(find.byType(Slider), findsOneWidget, reason: '倍速滑块两种模式都保留');

    await tester.pumpWidget(_host(aloud, mode: SpeechMode.fine));
    expect(find.text('开始'), findsOneWidget);
    expect(find.text('结束'), findsOneWidget);
    expect(find.text('清除范围'), findsOneWidget);
    expect(find.text('未设范围'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('精读三态：等待起点 / 待终点 / 范围已定', (tester) async {
    final aloud = ReadingAloud(engine: FakeSpeechEngine());
    aloud.attach('x', ['one two', 'three four', 'five six']);
    await aloud.playRange(
        const SpeechRange(SpeechAnchor(0, 2), SpeechAnchor(2, 3)));

    await tester.pumpWidget(
        _host(aloud, mode: SpeechMode.fine, phase: MarkPhase.awaitStart));
    expect(find.text('等待起点'), findsOneWidget);
    expect(_tapTarget(tester, '开始').onTap, isNotNull);

    await tester.pumpWidget(
        _host(aloud, mode: SpeechMode.fine, phase: MarkPhase.awaitEnd));
    expect(find.text('起点已设 · 待终点'), findsOneWidget);
    expect(_tapTarget(tester, '结束').onTap, isNotNull);

    await tester.pumpWidget(
        _host(aloud, mode: SpeechMode.fine, phase: MarkPhase.done));
    expect(find.text('第 1–3 段'), findsOneWidget);
    expect(find.textContaining('选区朗读'), findsOneWidget);
  });

  testWidgets('未设起点时「结束」不可点', (tester) async {
    final aloud = ReadingAloud(engine: FakeSpeechEngine());
    await tester.pumpWidget(_host(aloud, mode: SpeechMode.fine));
    expect(_tapTarget(tester, '结束').onTap, isNull);

    await tester.pumpWidget(
        _host(aloud, mode: SpeechMode.fine, phase: MarkPhase.awaitStart));
    expect(_tapTarget(tester, '结束').onTap, isNotNull);
  });

  testWidgets('三个按钮各自回调独立', (tester) async {
    var starts = 0;
    var ends = 0;
    var clears = 0;
    final aloud = ReadingAloud(engine: FakeSpeechEngine());
    await tester.pumpWidget(_host(
      aloud,
      mode: SpeechMode.fine,
      phase: MarkPhase.awaitEnd,
      onStart: () => starts++,
      onEnd: () => ends++,
      onClear: () => clears++,
    ));

    await tester.tap(find.text('开始'));
    await tester.tap(find.text('结束'));
    await tester.tap(find.text('清除范围'));
    await tester.pump();

    expect(starts, 1);
    expect(ends, 1);
    expect(clears, 1);
  });

  testWidgets('精读行在 360dp 小屏不溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final aloud = ReadingAloud(engine: FakeSpeechEngine());
    await tester.pumpWidget(_host(aloud, mode: SpeechMode.fine));
    expect(tester.takeException(), isNull);
    expect(find.text('开始'), findsOneWidget);
    expect(find.text('结束'), findsOneWidget);
    expect(find.text('清除范围'), findsOneWidget);
  });
}
