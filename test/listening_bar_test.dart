import 'package:cet6_app/app/theme.dart';
import 'package:cet6_app/features/reading_mode/reading_aloud.dart';
import 'package:cet6_app/features/reading_mode/reading_mode_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(ReadingAloud aloud) => MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(bottomNavigationBar: ListeningBar(aloud: aloud, sourceKey: 'x')),
    );

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
}
