import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/notifications/reminder_service.dart';
import 'core/spec/day_repository.dart';
import 'core/storage/app_store.dart';
import 'core/storage/db.dart';
import 'core/storage/secure.dart';
import 'domain/grading.dart';
import 'domain/profile.dart';
import 'domain/training_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore(AppDatabase());
  await store.load();
  final repo = DayRepository(
    goal: () => store.goal,
    generated: () => store.generatedDays.map((k, v) => MapEntry(k, v.payload)),
  );
  final index = await repo.index();
  final secure = SecureApiConfigStore();
  final apiConfig = await secure.read();

  final today = DateTime.now();
  final todayKey = today.toIso8601String().substring(0, 10);
  // 按档恢复：1.0 的全局 lastDay 作为六级的历史值兜底。
  final lastDay = int.tryParse(
      store.setting(TrainingScope.keyLastDay(store.goal)) ?? store.setting('lastDay') ?? '');
  final chosenToday = store.setting('lastDayOn') == todayKey;
  final initialDay = chosenToday && lastDay != null && index.any((e) => e.day == lastDay)
      ? lastDay
      : pickDefaultDay(index, today);

  // 每日提醒：冷启动点通知默认就落在今日页；这里只负责初始化与幂等重排，
  // 覆盖开机、时区变化、覆盖安装后本机设置与系统排程可能不一致的情况。
  await ReminderService.initialize(
    onTap: (payload) {
      if (payload == kReminderPayload) appRouter.go('/today');
    },
  );
  await ReminderService.apply(ReminderSettings.fromSettings(store.setting));

  runApp(ProviderScope(
    overrides: [
      storeProvider.overrideWithValue(store),
      dayRepositoryProvider.overrideWithValue(repo),
      initialDayProvider.overrideWithValue(initialDay),
      apiConfigStoreProvider.overrideWithValue(secure),
      initialApiConfigProvider.overrideWithValue(apiConfig),
    ],
    child: const Cet6App(),
  ));
}

ThemeMode themeModeOf(String? v) => switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

class Cet6App extends ConsumerWidget {
  const Cet6App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StoreBuilder(
      builder: (context, store) => MaterialApp.router(
        title: '一页英语',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: themeModeOf(store.setting('themeMode')),
        // 中文界面固定用中文 Material 文案（日期选择器、对话框按钮等）。
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: appRouter,
      ),
    );
  }
}
