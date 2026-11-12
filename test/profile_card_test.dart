// 身份卡：四格数据（含倒计时第 4 格）、等高、点选与浅深主题。
import 'package:cet6_app/app/theme.dart';
import 'package:cet6_app/domain/profile.dart';
import 'package:cet6_app/ui/components/profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
      theme: buildTheme(brightness),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Widget _card({
  required Profile profile,
  required VoidCallback onCountdownTap,
}) =>
    ProfileCard(
      profile: profile,
      goalName: '六级',
      stats: const ProfileStats(streak: 6, done: 12, currentDay: 10),
      today: DateTime(2026, 11, 11),
      onEdit: () {},
      onCountdownTap: onCountdownTap,
    );

void main() {
  testWidgets('四格数据：连续完成 / 已完成 / 当前进度 / 距考试', (tester) async {
    await tester.pumpWidget(_host(_card(
      profile: const Profile(nickname: '王工', examDate: '2026-12-21'),
      onCountdownTap: () {},
    )));

    expect(find.text('王工'), findsOneWidget);
    expect(find.text('六级 · 自主备考 · 每天一页'), findsOneWidget);
    for (final label in ['连续完成', '已完成', '当前进度', '距考试']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('40'), findsOneWidget);
    expect(find.byType(IntrinsicHeight), findsOneWidget, reason: '四格用自然高度拉齐');
  });

  testWidgets('四格标签同一基线、格子等高', (tester) async {
    await tester.pumpWidget(_host(_card(
      profile: const Profile(examDate: '2026-12-21'),
      onCountdownTap: () {},
    )));
    final labels = ['连续完成', '已完成', '当前进度', '距考试'];
    final rects = labels.map((t) => tester.getRect(find.text(t))).toList();
    for (final r in rects) {
      expect(r.top, closeTo(rects.first.top, 1.0), reason: '第 4 格可点也不能让基线错位');
      expect(r.height, closeTo(rects.first.height, 1.0));
    }
  });

  testWidgets('倒计时四种日期态都落在第 4 格', (tester) async {
    final cases = <(String, String, String)>[
      ('', '—', '未设考试日'),
      ('2026-11-11', '今天', '考试日'),
      ('2026-10-01', '已过', '更新考试日'),
      ('2026-12-21', '40', '距考试'),
    ];
    for (final (date, value, label) in cases) {
      await tester.pumpWidget(_host(_card(
        profile: Profile(examDate: date),
        onCountdownTap: () {},
      )));
      expect(find.text(label), findsOneWidget, reason: '$date 的标签');
      expect(find.textContaining(value), findsWidgets, reason: '$date 的数值');
    }
  });

  testWidgets('点第 4 格触发回调，并带完整语义标签', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_host(_card(
      profile: const Profile(examDate: '2026-12-21'),
      onCountdownTap: () => tapped++,
    )));
    expect(find.bySemanticsLabel(RegExp('点击修改考试日期')), findsOneWidget);
    await tester.tap(find.text('距考试'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('系统字体放大时四格标签不截断', (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
      child: _host(_card(
        profile: const Profile(examDate: ''),
        onCountdownTap: () {},
      )),
    ));
    expect(tester.takeException(), isNull);
    // 每格标签都包在 FittedBox 里，超出宽度时整体缩放而非省略号截断。
    expect(find.byType(FittedBox), findsNWidgets(4));
    for (final label in ['连续完成', '已完成', '当前进度', '未设考试日']) {
      expect(find.text(label), findsOneWidget, reason: '$label 应完整存在');
    }
  });

  testWidgets('深色主题下身份卡与四格仍完整渲染', (tester) async {
    await tester.pumpWidget(_host(
      _card(profile: const Profile(nickname: '阿笔', avatar: 3, examDate: '2026-12-21'),
          onCountdownTap: () {}),
      brightness: Brightness.dark,
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('阿笔'), findsOneWidget);
    expect(find.text('阿'), findsOneWidget, reason: '头像首字');
    expect(find.text('距考试'), findsOneWidget);
  });
}
