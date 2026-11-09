/// Day 标题相关的纯文本工具。
/// 今日页的 DayHeader / StampBadge 已移除；这些函数仍被题库 Day 卡片、
/// 笔记页、复盘页、设置页与生成页使用，勿删。
const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String formatDayDate(String isoDate) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return isoDate;
  return '${d.month} 月 ${d.day} 日 · ${_weekdays[d.weekday - 1]}';
}

String dayLabel(int day) => 'Day ${day.toString().padLeft(2, '0')}';
