// 复盘页顶部档位卡：只读字样下线、标题行与三档 Chip 居中、点选仍然可用。
import 'package:cet6_app/app/theme.dart';
import 'package:cet6_app/domain/training_scope.dart';
import 'package:cet6_app/features/review/review_page.dart';
import 'package:cet6_app/ui/components/paper_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: child),
    );

Widget _card(ValueChanged<GoalId> onSelect) => GoalFilterCard(
      selected: GoalId.cet6,
      onSelect: onSelect,
    );

void main() {
  testWidgets('不再显示「只读」，标题行与 Chip 组都居中', (tester) async {
    await tester.pumpWidget(_host(_card((_) {})));

    expect(find.text('只读'), findsNothing);
    expect(find.text('按备考目标查看'), findsOneWidget);
    for (final g in kGoals) {
      expect(find.text(g.name), findsOneWidget);
    }

    final column = tester.widget<Column>(find.byType(Column));
    expect(column.crossAxisAlignment, CrossAxisAlignment.stretch,
        reason: '子行要占满卡片宽度，居中才有意义');
    final row = tester.widget<Row>(find.byType(Row));
    expect(row.mainAxisAlignment, MainAxisAlignment.center);
    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.alignment, WrapAlignment.center);
  });

  testWidgets('三档 Chip 组在卡片内左右留白对称', (tester) async {
    await tester.pumpWidget(_host(_card((_) {})));
    final card = tester.getRect(find.byType(PaperCard));
    final first = tester.getRect(find.text(kGoals.first.name));
    final last = tester.getRect(find.text(kGoals.last.name));
    expect(first.left - card.left, closeTo(card.right - last.right, 2.0),
        reason: '去掉「只读」后 Chip 组应整体居中，不能还贴着左边');
  });

  testWidgets('点选档位仍把目标 id 交给外层', (tester) async {
    GoalId? picked;
    await tester.pumpWidget(_host(_card((id) => picked = id)));
    await tester.tap(find.text('考研'));
    await tester.pump();
    expect(picked, GoalId.kaoyan);
  });
}
