// 个人资料 / 提醒设置的本机键、考试倒计时四态与排程时刻计算。
import 'package:cet6_app/core/backup/backup_codec.dart';
import 'package:cet6_app/core/notifications/reminder_service.dart';
import 'package:cet6_app/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, String> _bag(Map<String, String> initial) => Map.of(initial);
String? _read(Map<String, String> bag, String key) => bag[key];

void main() {
  group('Profile 本机键', () {
    test('默认态：昵称回退、未设考试日、每天一页', () {
      final p = Profile.fromSettings((_) => null);
      expect(p.displayName, '同学');
      expect(p.initial, '同');
      expect(p.identity, ProfileIdentity.other);
      expect(p.dailyGoal, DailyGoal.everyDay);
      expect(p.examDate, '');
      expect(p.subLine('六级'), '六级 · 自主备考 · 每天一页');
    });

    test('toSettings / fromSettings 往返一致', () {
      const p = Profile(
        nickname: '王工',
        avatar: 2,
        identity: ProfileIdentity.working,
        examDate: '2026-12-21',
        dailyGoal: DailyGoal.weekdays,
      );
      final bag = _bag(p.toSettings());
      final back = Profile.fromSettings((k) => _read(bag, k));
      expect(back.displayName, '王工');
      expect(back.initial, '王');
      expect(back.avatar, 2);
      expect(back.identity, ProfileIdentity.working);
      expect(back.examDate, '2026-12-21');
      expect(back.dailyGoal, DailyGoal.weekdays);
    });

    test('所有 profile.* / reminder.* 键都不会被备份当作凭据过滤', () {
      final all = {
        ...const Profile().toSettings(),
        ...const ReminderSettings().toSettings(),
      };
      for (final key in all.keys) {
        expect(isSensitiveSettingKey(key), isFalse, reason: '$key 必须随备份 v2 一起导出 / 导入');
      }
    });

    test('身份与每日目标的未知编码回落到默认值', () {
      final bag = {
        'profile.identity': 'nonsense',
        'profile.dailyGoal': 'nonsense',
        'profile.avatar': 'abc',
        'profile.nickname': '  ',
      };
      final p = Profile.fromSettings((k) => _read(bag, k));
      expect(p.identity, ProfileIdentity.other);
      expect(p.dailyGoal, DailyGoal.everyDay);
      expect(p.avatar, 0);
      expect(p.displayName, '同学');
    });
  });

  group('ReminderSettings', () {
    test('往返一致，时间补零', () {
      const s = ReminderSettings(enabled: true, hour: 7, minute: 5, exact: true);
      final bag = _bag(s.toSettings());
      final back = ReminderSettings.fromSettings((k) => _read(bag, k));
      expect(back.enabled, isTrue);
      expect(back.exact, isTrue);
      expect(back.timeLabel, '07:05');
      expect(back.hour, 7);
      expect(back.minute, 5);
    });

    test('越界时间回落到 20:00，默认关闭', () {
      final back = ReminderSettings.fromSettings((k) => switch (k) {
            'reminder.hour' => '99',
            'reminder.minute' => '120',
            _ => null,
          });
      expect(back.timeLabel, '20:00');
      expect(back.enabled, isFalse);
      expect(back.exact, isFalse);
    });
  });

  group('考试倒计时', () {
    final today = DateTime(2026, 11, 11, 23, 40);

    test('按本地日期差计算，忽略时分秒', () {
      expect(daysToExam('2026-12-21', today), 40);
      expect(daysToExam('2026-11-11', today), 0);
      expect(daysToExam('2026-10-01', today), -41);
    });

    test('空值与非法日期视为未设置', () {
      expect(daysToExam(null, today), isNull);
      expect(daysToExam('', today), isNull);
      expect(daysToExam('不是日期', today), isNull);
    });

    test('第 4 格四种展示态', () {
      expect(countdownCell(40).value, '40');
      expect(countdownCell(40).unit, '天');
      expect(countdownCell(40).label, '距考试');
      expect(countdownCell(null).value, '—');
      expect(countdownCell(null).label, '未设考试日');
      expect(countdownCell(0).value, '今天');
      expect(countdownCell(0).label, '考试日');
      expect(countdownCell(-1).value, '已过');
      expect(countdownCell(-1).label, '更新考试日');
      expect(countdownCell(-1).value, isNot(contains('-')), reason: '不出现负数');
    });
  });

  group('每日提醒排程时刻', () {
    test('今天未过点取今天，已过点取明天', () {
      final before = DateTime(2026, 11, 11, 7, 0);
      final after = DateTime(2026, 11, 11, 21, 0);
      expect(nextOccurrenceAt(before, 20, 0), DateTime(2026, 11, 11, 20, 0));
      expect(nextOccurrenceAt(after, 20, 0), DateTime(2026, 11, 12, 20, 0));
    });

    test('恰好整点也算已过，排到明天', () {
      final now = DateTime(2026, 11, 11, 20, 0);
      expect(nextOccurrenceAt(now, 20, 0), DateTime(2026, 11, 12, 20, 0));
    });

    test('跨月末与跨年按日历日推进，不丢失时刻', () {
      expect(nextOccurrenceAt(DateTime(2026, 11, 30, 21, 0), 20, 0), DateTime(2026, 12, 1, 20, 0));
      expect(nextOccurrenceAt(DateTime(2026, 12, 31, 21, 0), 7, 30), DateTime(2027, 1, 1, 7, 30));
    });
  });
}
