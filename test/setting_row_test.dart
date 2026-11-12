// 「我的」分组行的可访问性与分隔线，以及外观选项文案。
import 'package:cet6_app/app/theme.dart';
import 'package:cet6_app/features/settings/settings_page.dart';
import 'package:cet6_app/ui/components/setting_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

SettingRow _row({required VoidCallback onTap, String? subtitle, String? value}) => SettingRow(
      icon: Icons.flag_outlined,
      title: '备考目标',
      subtitle: subtitle,
      value: value,
      onTap: onTap,
    );

void main() {
  testWidgets('整行是一个语义按钮，主标题 / 副标题 / 右侧值都可读', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_host(_row(
      onTap: () => tapped++,
      subtitle: '六级 · CET-6',
      value: '已配置',
    )));
    expect(find.text('备考目标'), findsOneWidget);
    expect(find.text('六级 · CET-6'), findsOneWidget);
    expect(find.text('已配置'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('备考目标，')), findsWidgets);
    final rect = tester.getRect(find.byType(SettingRow));
    expect(rect.height, greaterThanOrEqualTo(44), reason: '触控区不小于 44px');
    await tester.tap(find.text('备考目标'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('分组卡在相邻行之间自动补分隔线', (tester) async {
    final group = SettingGroup(rows: [
      _row(onTap: () {}),
      _row(onTap: () {}, value: '第二行'),
      _row(onTap: () {}, value: '第三行'),
    ]);
    await tester.pumpWidget(_host(group));
    expect(find.byType(SettingRow), findsNWidgets(3));
    expect(find.byType(Divider), findsNWidgets(2));
  });

  test('外观三态文案', () {
    expect(themeModeLabel(null), '跟随系统');
    expect(themeModeLabel('system'), '跟随系统');
    expect(themeModeLabel('light'), '浅色');
    expect(themeModeLabel('dark'), '深色');
  });
}
