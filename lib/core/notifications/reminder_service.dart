import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/profile.dart';

const kReminderNotificationId = 1001;
const kTestNotificationId = 1002;
const kReminderChannelId = 'daily_reminder';
const kReminderPayload = 'today';

enum ReminderApplyResult { scheduled, disabled, permissionDenied, failed }

class ReminderStatus {
  const ReminderStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
    required this.scheduled,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsAllowed;
  final bool scheduled;
}

/// 下一个提醒时刻（纯本地日历日计算，不涉及时分秒以外的时区逻辑）。
/// 用 `DateTime(y, m, d + 1, ...)` 而不是 `add(Duration(days: 1))`，
/// 跨月末 / 夏令时都不会把时刻推偏。
DateTime nextOccurrenceAt(DateTime now, int hour, int minute) {
  final todayAt = DateTime(now.year, now.month, now.day, hour, minute);
  return todayAt.isAfter(now)
      ? todayAt
      : DateTime(now.year, now.month, now.day + 1, hour, minute);
}

/// 每日提醒的本机通知服务。仅 Android 出包，不联网、不上传任何内容。
///
/// 默认使用 `inexactAllowWhileIdle`：Android 14 起 SCHEDULE_EXACT_ALARM
/// 对新装应用默认拒绝，用 exact 会静默不响。用户主动开「准点模式」时
/// 才检查 / 引导授权，未授权自动降级回 inexact。
class ReminderService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static void Function(String? payload)? onNotificationTap;

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          kReminderChannelId,
          '每日提醒',
          channelDescription: '到点提醒练今天这一页；只在本机发出',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  static Future<void> initialize({void Function(String? payload)? onTap}) async {
    if (onTap != null) onNotificationTap = onTap;
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // 少数 ROM 会回报非 IANA 名称；兜底到中国标准时，最后退到 UTC。
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        // 原生侧用 getIdentifier(name, "drawable", pkg) 解析，必须是纯资源名。
        android: AndroidInitializationSettings('ic_stat_book'),
      ),
      onDidReceiveNotificationResponse: (response) => onNotificationTap?.call(response.payload),
    );
    _initialized = true;
  }

  /// 幂等重排：App 启动、设置变更、导入备份、时区变化都调它。
  static Future<ReminderApplyResult> apply(ReminderSettings settings) async {
    try {
      await initialize();
      await _plugin.cancel(id: kReminderNotificationId);
      if (!settings.enabled) return ReminderApplyResult.disabled;

      if (!await requestNotificationPermission()) {
        return ReminderApplyResult.permissionDenied;
      }
      final mode = settings.exact && await exactAlarmsAllowed()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      final next = nextOccurrenceAt(DateTime.now(), settings.hour, settings.minute);
      final scheduled = tz.TZDateTime(
          tz.local, next.year, next.month, next.day, next.hour, next.minute);
      await _plugin.zonedSchedule(
        id: kReminderNotificationId,
        scheduledDate: scheduled,
        notificationDetails: _details,
        androidScheduleMode: mode,
        title: '该练今天这一页了',
        body: '2 篇阅读、1 段翻译、1 篇写作，花半小时和艾笔过一遍。',
        payload: kReminderPayload,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return ReminderApplyResult.scheduled;
    } catch (_) {
      return ReminderApplyResult.failed;
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    await initialize();
    return await _android?.areNotificationsEnabled() ?? true;
  }

  /// 只在用户开启提醒时申请 Android 13+ POST_NOTIFICATIONS；已开启则直接返回。
  static Future<bool> requestNotificationPermission() async {
    await initialize();
    final android = _android;
    if (android == null) return true;
    if (await android.areNotificationsEnabled() ?? true) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  static Future<bool> exactAlarmsAllowed() async {
    await initialize();
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  /// 打开系统「应用通知设置」；用于权限被永久拒绝后的引导。
  static Future<bool> openAppNotificationSettings() async {
    await initialize();
    return await _android?.openAppNotificationSettings() ?? false;
  }

  /// 准点模式授权入口（跳系统「闹钟与提醒」特殊权限页）。
  static Future<bool> requestExactAlarmsPermission() async {
    await initialize();
    return await _android?.requestExactAlarmsPermission() ?? false;
  }

  static Future<ReminderStatus> status() async {
    try {
      await initialize();
      final pending = await _plugin.pendingNotificationRequests();
      return ReminderStatus(
        notificationsEnabled: await areNotificationsEnabled(),
        exactAlarmsAllowed: await exactAlarmsAllowed(),
        scheduled: pending.any((p) => p.id == kReminderNotificationId),
      );
    } catch (_) {
      return const ReminderStatus(
        notificationsEnabled: false,
        exactAlarmsAllowed: false,
        scheduled: false,
      );
    }
  }

  /// 立即发一条测试通知，真机验证权限与渠道是否真的可用。
  static Future<bool> sendTest() async {
    try {
      await initialize();
      if (!await requestNotificationPermission()) return false;
      await _plugin.show(
        id: kTestNotificationId,
        title: '测试通知',
        body: '每日提醒已生效，到点会这样提醒你。',
        notificationDetails: _details,
        payload: kReminderPayload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
