// 复盘页三张统计卡：以内容最多的「本档标准」为高度基准，三张等高且顶部对齐。
import 'package:cet6_app/app/theme.dart';
import 'package:cet6_app/features/review/review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double textScale = 1.0}) => MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
            child: child,
          ),
        ),
      ),
    );

StatTileRow _row() => const StatTileRow(tiles: [
      StatTile(label: '已完成', value: '0', unit: '天'),
      StatTile(label: '连续完成', value: '0', unit: '天'),
      StatTile(label: '本档标准', value: '380', unit: '词/篇起'),
    ]);

List<RenderBox> _tiles(WidgetTester tester) =>
    find.byType(StatTile).evaluate().map((e) => e.renderObject! as RenderBox).toList();

void main() {
  testWidgets('三张统计卡等高，顶部也在同一水平线', (tester) async {
    await tester.pumpWidget(_host(_row()));
    final boxes = _tiles(tester);
    expect(boxes.length, 3);

    final heights = boxes.map((b) => b.size.height).toList();
    expect(heights[0], heights[1], reason: '已完成 / 连续完成 必须等高');
    expect(heights[1], heights[2], reason: '本档标准 是高度基准，另外两张要拉伸到同高');

    final tops = boxes.map((b) => b.localToGlobal(Offset.zero).dy).toList();
    expect(tops[0], tops[1]);
    expect(tops[1], tops[2], reason: '卡内文字仍顶部对齐，标签落在同一基线');
    expect(tester.takeException(), isNull, reason: '折行的单位不能被裁切');
  });

  testWidgets('字号放大到 1.3 倍时依然等高、不溢出', (tester) async {
    await tester.pumpWidget(_host(_row(), textScale: 1.3));
    final boxes = _tiles(tester);
    expect(boxes.length, 3);
    final heights = boxes.map((b) => b.size.height).toList();
    expect(heights[0], heights[1]);
    expect(heights[1], heights[2]);
    expect(tester.takeException(), isNull);
  });
}
