import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'paper_card.dart';

/// 「我的」页分组列表行：图标 + 主标题 / 状态副标题 + 右侧值 + 箭头。
/// 最小高度 56，触控区始终 ≥44；整行语义化为一个按钮。
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.danger = false,
    this.trailing,
    this.subtitleMaxLines = 1,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final bool danger;
  final Widget? trailing;
  final VoidCallback onTap;
  /// 危险操作的说明较长时允许两行，避免省略号把后果说明截掉。
  final int subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = danger ? c.red : c.blue;
    return Semantics(
      button: true,
      label: '$title${value == null ? '' : '，$value'}${subtitle == null ? '' : '，$subtitle'}',
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: danger ? c.red : c.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: subtitleMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: AppType.min, color: c.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: AppSpace.s2),
                  Text(value!, style: TextStyle(fontSize: 13, color: c.muted)),
                ],
                const SizedBox(width: AppSpace.s1),
                trailing ?? Icon(Icons.chevron_right, size: 18, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 一组行共用一张卷面卡，行间分隔线从文字起点起排（不穿过图标）。
class SettingGroup extends StatelessWidget {
  const SettingGroup({super.key, required this.rows});

  final List<SettingRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PaperCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 48, color: c.lineSoft),
            rows[i],
          ],
        ],
      ),
    );
  }
}
