import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 采分点勾选。
class ScoringPointTile extends StatelessWidget {
  const ScoringPointTile({super.key, required this.zh, required this.en, required this.checked, required this.onChanged});

  final String zh;
  final String en;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s2),
      child: Material(
        color: checked ? c.greenSoft : c.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: checked ? c.green : c.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => onChanged(!checked),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, color: checked ? c.green : c.muted, size: 22),
                const SizedBox(width: AppSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zh, style: TextStyle(fontSize: 14, color: c.ink)),
                      const SizedBox(height: 2),
                      Text(en, style: TextStyle(fontFamily: readingFont, fontSize: 14, color: c.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 词数提示：目标 170–190，150 以下提醒不足，200 以上提醒超出。
class WordCountChip extends StatelessWidget {
  const WordCountChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (Color fg, Color bg, String hint) = count < 150
        ? (c.muted, c.lineSoft, '至少 150')
        : count > 200
            ? (c.red, c.redSoft, '超过 200')
            : (count >= 170 && count <= 190) ? (c.green, c.greenSoft, '目标区间') : (c.blue, c.blueSoft, '目标 170–190');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        '$count 词 · $hint',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg, fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.text, {super.key, this.serif = false});

  final String text;
  final bool serif;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.paper,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: c.inkSoft, fontFamily: serif ? readingFont : null)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
      child: Column(
        children: [
          Icon(icon, size: 36, color: c.muted),
          const SizedBox(height: AppSpace.s3),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (message != null) ...[
            const SizedBox(height: AppSpace.s1),
            Text(message!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.muted)),
          ],
        ],
      ),
    );
  }
}

/// 可折叠区块（全文翻译、范文译文等）。
class FoldSection extends StatelessWidget {
  const FoldSection({super.key, required this.title, required this.child, this.initiallyExpanded = false, this.icon});

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpace.s3),
        leading: icon == null ? null : Icon(icon, color: c.blue, size: 20),
        iconColor: c.blue,
        collapsedIconColor: c.muted,
        title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [child],
      ),
    );
  }
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}
