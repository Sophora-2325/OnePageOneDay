// 四步状态栏一致性：短名、不限时态 ∞、只读按钮的反馈。
import 'package:cet6_app/app/theme.dart';
import 'package:cet6_app/core/spec/day_model.dart';
import 'package:cet6_app/domain/countdown.dart';
import 'package:cet6_app/ui/components/timer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpBar(WidgetTester tester, Widget bar) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Scaffold(body: bar),
  ));
}

void main() {
  test('短名：文A / 文B；描述性文案仍用完整 label', () {
    final r1 = Reading.fromJson({'id': 'r1', 'title': 't', 'questions': []});
    final r2 = Reading.fromJson({'id': 'r2', 'title': 't', 'questions': []});
    expect(r1.shortLabel, '文A');
    expect(r2.shortLabel, '文B');
    expect(r1.label, '阅读 A');
    expect(r2.label, '阅读 B');
  });

  testWidgets('计时态：文A · 09:00，不出现 ∞', (tester) async {
    final cd = Countdown(const Duration(minutes: 9));
    addTearDown(cd.dispose);
    await pumpBar(tester, TimerBar(label: '文A', countdown: cd));
    expect(find.text('文A'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('∞'), findsNothing);
  });

  testWidgets('不限时态：笔记 · ∞，开始与重置按钮都在', (tester) async {
    await pumpBar(tester, const TimerBar(label: '笔记'));
    expect(find.text('笔记'), findsOneWidget);
    expect(find.text('∞'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
  });

  testWidgets('不限时态：开始键只切图标，永远是 ∞', (tester) async {
    await pumpBar(tester, const TimerBar(label: '笔记'));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.text('∞'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('∞'), findsOneWidget);
  });

  testWidgets('不限时态：重置键给提示，不改动时间位', (tester) async {
    await pumpBar(tester, const TimerBar(label: '笔记'));
    await tester.tap(find.byIcon(Icons.replay_rounded));
    await tester.pumpAndSettle();
    expect(find.text('笔记不限时，无需重置'), findsOneWidget);
    expect(find.text('∞'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
