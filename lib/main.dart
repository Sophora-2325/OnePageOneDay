import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/spec/day_repository.dart';
import 'core/storage/app_store.dart';
import 'core/storage/db.dart';
import 'core/storage/secure.dart';
import 'domain/grading.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore(AppDatabase());
  await store.load();
  final repo = DayRepository(generated: () => store.generatedDays.map((k, v) => MapEntry(k, v.payload)));
  final index = await repo.index();
  final secure = SecureApiConfigStore();
  final apiConfig = await secure.read();

  final today = DateTime.now();
  final todayKey = today.toIso8601String().substring(0, 10);
  final lastDay = int.tryParse(store.setting('lastDay') ?? '');
  final chosenToday = store.setting('lastDayOn') == todayKey;
  final initialDay = chosenToday && lastDay != null && index.any((e) => e.day == lastDay)
      ? lastDay
      : pickDefaultDay(index, today);

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
        routerConfig: appRouter,
      ),
    );
  }
}
