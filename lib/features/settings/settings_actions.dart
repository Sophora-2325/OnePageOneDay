import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/notifications/reminder_service.dart';
import '../../core/storage/app_store.dart';
import '../../domain/profile.dart';
import '../../ui/components/day_header.dart';
import '../../ui/components/misc.dart';

/// 危险操作统一走二次确认，红色只出现在这里。
Future<bool> confirmDanger(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message, style: const TextStyle(height: 1.6)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.c.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> clearProfileData(BuildContext context, WidgetRef ref, AppStore store) async {
  final ok = await confirmDanger(
    context,
    title: '清除个人资料？',
    message: '昵称、头像、备考身份、考试日期与每日目标会恢复默认。学习记录、标注、笔记和提醒设置不受影响。此操作不可撤销。',
    action: '清除',
  );
  if (!ok) return;
  await store.clearSettingsWithPrefix(kProfilePrefix);
  if (context.mounted) showToast(context, '个人资料已清除');
}

Future<void> resetCurrentDay(BuildContext context, WidgetRef ref, AppStore store, int day) async {
  final ok = await confirmDanger(
    context,
    title: '重置 ${dayLabel(day)}？',
    message: '将清除本日阅读 / 听读作答、翻译和写作草稿、复盘内容。标注与笔记会保留。此操作不可撤销。',
    action: '重置',
  );
  if (!ok) return;
  await store.resetDay(day);
  ref.read(countdownHubProvider).resetDay(store.goal, day);
  if (context.mounted) showToast(context, '${dayLabel(day)} 已重置');
}

/// 写设置并立刻重排系统通知。权限被拒时回滚开关，不让 UI 显示一个假的「已开启」。
Future<void> applyReminderChange(
  BuildContext context,
  WidgetRef ref,
  AppStore store,
  ReminderSettings next,
) async {
  for (final e in next.toSettings().entries) {
    store.setSetting(e.key, e.value);
  }
  final result = await ReminderService.apply(next);
  if (!context.mounted) return;
  switch (result) {
    case ReminderApplyResult.permissionDenied:
      store.setSetting('${kReminderPrefix}enabled', '0');
      final go = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('通知权限未开启'),
              content: const Text('每日提醒需要系统通知权限。请在系统设置里允许「一页英语」发送通知，然后回来重新开启。',
                  style: TextStyle(height: 1.6)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('以后再说')),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('去系统设置'),
                ),
              ],
            ),
          ) ??
          false;
      if (go) await ReminderService.openAppNotificationSettings();
    case ReminderApplyResult.failed:
      showToast(context, '提醒设置失败，请重试');
    case ReminderApplyResult.scheduled:
      showToast(context, '已开启每日提醒 · 每天 ${next.timeLabel}');
    case ReminderApplyResult.disabled:
      showToast(context, '已关闭每日提醒');
  }
}
