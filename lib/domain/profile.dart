import '../core/storage/app_store.dart';
import 'day_summary.dart';
import 'training_scope.dart';

/// 本机个人资料与每日提醒设置。
///
/// 全部存 [AppStore] 的 settings 表：零表结构变更、零 migration，
/// 备份 v2 本来就全量导出 settings，因此随备份一起走。
/// 键名必须避开 [isSensitiveSettingKey] 的 key / token / secret / baseurl，
/// 否则会被当作凭据从备份里过滤掉。
const kProfilePrefix = 'profile.';
const kReminderPrefix = 'reminder.';

enum ProfileIdentity {
  student('在校备考', 'student'),
  working('在职备考', 'working'),
  other('自主备考', 'other');

  const ProfileIdentity(this.label, this.code);

  final String label;
  final String code;

  static ProfileIdentity fromCode(String? v) =>
      ProfileIdentity.values.where((e) => e.code == v).firstOrNull ?? ProfileIdentity.other;
}

enum DailyGoal {
  everyDay('每天一页', 'daily'),
  weekdays('每周 5 页', 'week5'),
  custom('自定义节奏', 'custom');

  const DailyGoal(this.label, this.code);

  final String label;
  final String code;

  static DailyGoal fromCode(String? v) =>
      DailyGoal.values.where((e) => e.code == v).firstOrNull ?? DailyGoal.everyDay;
}

/// 个人资料。没有账号、没有云同步，头像用本机预设色 + 昵称首字，
/// 不引入相册 / 文件权限，换机也能随备份完整恢复。
class Profile {
  const Profile({
    this.nickname = '',
    this.avatar = 0,
    this.identity = ProfileIdentity.other,
    this.examDate = '',
    this.dailyGoal = DailyGoal.everyDay,
  });

  final String nickname;

  /// 本机预设头像序号，取模 [avatarPalette] 长度。
  final int avatar;
  final ProfileIdentity identity;

  /// `yyyy-MM-dd`，空串代表未设置。
  final String examDate;
  final DailyGoal dailyGoal;

  static const keys = <String>{
    '${kProfilePrefix}nickname',
    '${kProfilePrefix}avatar',
    '${kProfilePrefix}identity',
    '${kProfilePrefix}examDate',
    '${kProfilePrefix}dailyGoal',
  };

  static Profile fromSettings(String? Function(String) read) => Profile(
        nickname: read('${kProfilePrefix}nickname') ?? '',
        avatar: int.tryParse(read('${kProfilePrefix}avatar') ?? '') ?? 0,
        identity: ProfileIdentity.fromCode(read('${kProfilePrefix}identity')),
        examDate: read('${kProfilePrefix}examDate') ?? '',
        dailyGoal: DailyGoal.fromCode(read('${kProfilePrefix}dailyGoal')),
      );

  Map<String, String> toSettings() => {
        '${kProfilePrefix}nickname': nickname,
        '${kProfilePrefix}avatar': '$avatar',
        '${kProfilePrefix}identity': identity.code,
        '${kProfilePrefix}examDate': examDate,
        '${kProfilePrefix}dailyGoal': dailyGoal.code,
      };

  Profile copyWith({
    String? nickname,
    int? avatar,
    ProfileIdentity? identity,
    String? examDate,
    DailyGoal? dailyGoal,
  }) =>
      Profile(
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        identity: identity ?? this.identity,
        examDate: examDate ?? this.examDate,
        dailyGoal: dailyGoal ?? this.dailyGoal,
      );

  String get displayName => nickname.trim().isEmpty ? '同学' : nickname.trim();

  /// 头像首字；空昵称回退到 displayName 的首字。
  String get initial => displayName.substring(0, 1).toUpperCase();

  String subLine(String goalName) => '$goalName · ${identity.label} · ${dailyGoal.label}';
}

/// 每日提醒。默认关闭；[exact] 为「准点模式」，需要系统精确闹钟授权。
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
    this.exact = false,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final bool exact;

  static const keys = <String>{
    '${kReminderPrefix}enabled',
    '${kReminderPrefix}hour',
    '${kReminderPrefix}minute',
    '${kReminderPrefix}exact',
  };

  static ReminderSettings fromSettings(String? Function(String) read) {
    final hour = int.tryParse(read('${kReminderPrefix}hour') ?? '') ?? 20;
    final minute = int.tryParse(read('${kReminderPrefix}minute') ?? '') ?? 0;
    return ReminderSettings(
      enabled: read('${kReminderPrefix}enabled') == '1',
      hour: hour >= 0 && hour < 24 ? hour : 20,
      minute: minute >= 0 && minute < 60 ? minute : 0,
      exact: read('${kReminderPrefix}exact') == '1',
    );
  }

  Map<String, String> toSettings() => {
        '${kReminderPrefix}enabled': enabled ? '1' : '0',
        '${kReminderPrefix}hour': '$hour',
        '${kReminderPrefix}minute': '$minute',
        '${kReminderPrefix}exact': exact ? '1' : '0',
      };

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute, bool? exact}) => ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        exact: exact ?? this.exact,
      );

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// 考试倒计时按**本地日期差**计算，不带时分秒，避免凌晨差一天。
/// 返回 null 表示未设置或格式非法；0 是当天；负数是已过期。
int? daysToExam(String? examDate, DateTime today) {
  final raw = examDate?.trim();
  if (raw == null || raw.isEmpty) return null;
  final d = DateTime.tryParse(raw);
  if (d == null) return null;
  final a = DateTime(today.year, today.month, today.day);
  final b = DateTime(d.year, d.month, d.day);
  return b.difference(a).inDays;
}

/// 身份卡第 4 格的展示态：大数字 / 小单位 / 下方标签。
class CountdownCell {
  const CountdownCell(this.value, this.unit, this.label);

  final String value;
  final String unit;
  final String label;
}

CountdownCell countdownCell(int? days) => switch (days) {
      null => const CountdownCell('—', '', '未设考试日'),
      0 => const CountdownCell('今天', '', '考试日'),
      > 0 => CountdownCell('$days', '天', '距考试'),
      _ => const CountdownCell('已过', '', '更新考试日'),
    };

/// 身份卡前三格。与复盘页统计同源：按当前档的复盘完成标记计算。
class ProfileStats {
  const ProfileStats({required this.streak, required this.done, required this.currentDay});

  final int streak;
  final int done;
  final int currentDay;
}

ProfileStats computeProfileStats(AppStore store, int currentDay) {
  final goal = store.goal;
  final maxRecord = <int>{
    goalOf(goal).presetDays,
    for (final e in store.attemptsFor(goal)) e.day,
    for (final e in store.reviewsFor(goal)) e.day,
    for (final e in store.generatedFor(goal)) e.day,
  }.reduce((a, b) => a > b ? a : b);
  final days = [for (var d = 1; d <= maxRecord.clamp(1, 60); d++) d];
  final done = store.reviewsFor(goal).where((e) => e.done).map((e) => e.day).toSet();
  return ProfileStats(
    streak: completionStreak(days, done),
    done: done.length,
    currentDay: currentDay,
  );
}
