import 'package:flutter/material.dart';

import '../../app/theme.dart';

const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String formatDayDate(String isoDate) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return isoDate;
  return '${d.month} 月 ${d.day} 日 · ${_weekdays[d.weekday - 1]}';
}

String dayLabel(int day) => 'Day ${day.toString().padLeft(2, '0')}';

/// 方章式标签，如「原创仿写」。
class StampBadge extends StatelessWidget {
  const StampBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Transform.rotate(
      angle: -0.03,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        // 红只属于批改 / 错误 / 超时；「原创仿写」是中性标签。
        decoration: BoxDecoration(
          border: Border.all(color: c.line, width: 1.4),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: AppType.min, fontWeight: FontWeight.w700, color: c.inkSoft, letterSpacing: 1)),
      ),
    );
  }
}

class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.day,
    required this.date,
    required this.theme,
    this.onToggleTheme,
    this.isDark = false,
  });

  final int day;
  final String date;
  final String theme;
  final VoidCallback? onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatDayDate(date), style: TextStyle(fontSize: 13, color: c.muted)),
              const SizedBox(height: 2),
              Text(dayLabel(day), style: t.headlineSmall?.copyWith(fontSize: 28, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(theme, style: TextStyle(fontSize: 14, color: c.inkSoft)),
            ],
          ),
        ),
        // v1.3：主题切换唯一入口在「我的 → 外观」，今日首屏不再放这个按钮。
        if (onToggleTheme != null) ...[
          Material(
            color: c.paper,
            shape: CircleBorder(side: BorderSide(color: c.line)),
            child: IconButton(
              tooltip: isDark ? '切换为浅色' : '切换为深色',
              onPressed: onToggleTheme,
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: c.ink),
            ),
          ),
          const SizedBox(width: AppSpace.s3),
        ],
        const Padding(padding: EdgeInsets.only(top: 10), child: StampBadge('原创仿写')),
      ],
    );
  }
}
