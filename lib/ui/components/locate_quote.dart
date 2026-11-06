import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 定位引文的两种呈现形态，色值永远同源。
enum LocateVariant { inline, card }

/// 定位引文唯一 Component Set（v1.3 收敛）。
///
/// - [LocateVariant.inline]：正文 / 朗读模式里的一段定位文字，圆角 2。
/// - [LocateVariant.card]：判分后的解析卡，圆角 8，带「在原文定位」动作。
///
/// 正文 `SelectableText.rich` 无法整体包 Container 时，用 [inlineStyle]
/// 取同一组底色与前景，禁止调用方再写 `withValues(alpha:)` 自行叠色。
class LocateQuote extends StatelessWidget {
  const LocateQuote({
    super.key,
    required this.para,
    required this.quote,
    this.onLocate,
    this.variant = LocateVariant.card,
  });

  final int para;
  final String quote;
  final VoidCallback? onLocate;
  final LocateVariant variant;

  /// 唯一的色值出口：深浅主题都取实色 markerSoft，
  /// 深色下 ink(#E9EEF2) / markerSoft(#4A3E18) = 9.02:1。
  static Color background(BuildContext context) => context.c.markerSoft;

  static Color foreground(BuildContext context) => context.c.ink;

  static TextStyle inlineStyle(BuildContext context) => TextStyle(
        backgroundColor: background(context),
        color: foreground(context),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isCard = variant == LocateVariant.card;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background(context),
        borderRadius: BorderRadius.circular(isCard ? AppRadius.md : AppRadius.sm - 2),
        border: Border(left: BorderSide(color: c.marker, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpace.s3, AppSpace.s2, AppSpace.s2, AppSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.my_location, size: 14, color: foreground(context)),
              const SizedBox(width: 6),
              Text(
                '定位 · 第 $para 段',
                style: TextStyle(fontSize: AppType.min, fontWeight: FontWeight.w700, color: foreground(context)),
              ),
              const Spacer(),
              if (isCard && onLocate != null)
                TextButton.icon(
                  onPressed: onLocate,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s2),
                  ),
                  icon: Icon(Icons.my_location, size: 16, color: c.blue),
                  label: Text('在原文定位',
                      style: TextStyle(color: c.blue, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          Text(
            quote,
            style: TextStyle(
              fontFamily: readingFont,
              fontSize: 15,
              height: 1.55,
              color: foreground(context),
            ),
          ),
        ],
      ),
    );
  }
}
