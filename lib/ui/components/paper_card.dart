import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 卷面卡片：1px 冷灰描边 + 极轻阴影。
class PaperCard extends StatelessWidget {
  const PaperCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpace.s5), this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.line),
        boxShadow: const [
          BoxShadow(color: Color(0x0D17222E), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x1417222E), blurRadius: 24, offset: Offset(0, 12), spreadRadius: -12),
        ],
      ),
      child: child,
    );
  }
}

/// 卡片里的小号大写栏目标签，如 READING PASSAGE。
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: color ?? context.c.blue,
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpace.s2, bottom: AppSpace.s2),
        child: Row(
          children: [
            Expanded(child: Text(text, style: Theme.of(context).textTheme.titleSmall)),
            ?trailing,
          ],
        ),
      );
}
