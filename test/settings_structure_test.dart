// 配置回归：绿盾卡已下线、二级路由齐全、每日提醒的 Android 装配不会被误删。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _src(String path) => File(path).readAsStringSync();

void main() {
  test('「我的」首屏不再有「数据流向」绿盾卡与静态合规说明', () {
    final s = _src('lib/features/settings/settings_page.dart');
    expect(s.contains('数据流向'), isFalse);
    expect(s.contains('_FlowLine'), isFalse);
    expect(s.contains('shield_outlined'), isFalse);
    expect(s.contains('没有账号、没有云同步'), isFalse);
    expect(s.contains('ProfileCard'), isTrue);
    expect(s.contains('我的训练'), isTrue);
    expect(s.contains('通用设置'), isTrue);
  });

  test('五张二级页都挂在根 Navigator 上，点倒计时可直达资料页', () {
    final s = _src('lib/app/router.dart');
    for (final path in [
      '/me/profile',
      '/me/reminder',
      '/me/backup',
      '/me/data',
      '/me/about',
    ]) {
      expect(s.contains("path: '$path'"), isTrue, reason: '$path 路由缺失');
    }
    expect(s.contains("queryParameters['exam']"), isTrue);
    expect(s.contains('parentNavigatorKey: _rootKey'), isTrue);
  });

  test('每日提醒在启动与导入备份后都会重排', () {
    expect(_src('lib/main.dart').contains('ReminderService.apply'), isTrue);
    expect(_src('lib/app/providers.dart').contains('ReminderService.apply'), isTrue);
    expect(_src('lib/main.dart').contains("kReminderPayload) appRouter.go('/today')"), isTrue);
  });

  test('Android 权限、开机重排与 desugaring 装配齐全，且不声明 USE_EXACT_ALARM', () {
    final manifest = _src('android/app/src/main/AndroidManifest.xml');
    for (final item in [
      'POST_NOTIFICATIONS',
      'RECEIVE_BOOT_COMPLETED',
      'SCHEDULE_EXACT_ALARM',
      'ScheduledNotificationReceiver',
      'ScheduledNotificationBootReceiver',
      'BOOT_COMPLETED',
      'MY_PACKAGE_REPLACED',
    ]) {
      expect(manifest.contains(item), isTrue, reason: '$item 缺失');
    }
    expect(manifest.contains('USE_EXACT_ALARM'), isFalse,
        reason: 'Play 受限权限，本 App 不是闹钟类应用');

    final gradle = _src('android/app/build.gradle.kts');
    expect(gradle.contains('isCoreLibraryDesugaringEnabled = true'), isTrue);
    expect(gradle.contains('desugar_jdk_libs'), isTrue);
  });

  test('默认不精确模式，exact 只在授权后启用', () {
    final s = _src('lib/core/notifications/reminder_service.dart');
    expect(s.contains('AndroidScheduleMode.inexactAllowWhileIdle'), isTrue);
    expect(s.contains('canScheduleExactNotifications'), isTrue);
    expect(s.contains('DateTimeComponents.time'), isTrue);
  });

  test('Material 组件固定中文文案，日期选择器不回落成英文', () {
    final main = _src('lib/main.dart');
    expect(main.contains('flutter_localizations/flutter_localizations.dart'), isTrue);
    expect(main.contains("Locale('zh', 'CN')"), isTrue);
    expect(main.contains('GlobalMaterialLocalizations.delegate'), isTrue);
    expect(main.contains('supportedLocales'), isTrue);
    expect(_src('pubspec.yaml').contains('flutter_localizations:'), isTrue);
  });

  test('危险操作说明允许两行，不被省略号截断', () {
    final page = _src('lib/features/settings/local_data_page.dart');
    expect(RegExp('subtitleMaxLines: 2').allMatches(page).length, 2);
    expect(_src('lib/ui/components/setting_row.dart').contains('maxLines: subtitleMaxLines'), isTrue);
  });

  test('通知小图标用纯 drawable 资源名，且被 R8 keep 规则保留', () {
    final service = _src('lib/core/notifications/reminder_service.dart');
    expect(service.contains("AndroidInitializationSettings('ic_stat_book')"), isTrue);
    expect(service.contains("'@drawable/"), isFalse,
        reason: '原生 getIdentifier 只认纯资源名，带前缀会解析成 0 导致通知静默失败');
    final keep = _src('android/app/src/main/res/raw/keep.xml');
    expect(keep.contains('@drawable/ic_stat_book'), isTrue);
    expect(File('android/app/src/main/res/drawable/ic_stat_book.xml').existsSync(), isTrue);
  });
}
