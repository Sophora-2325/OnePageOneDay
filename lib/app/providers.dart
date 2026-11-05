import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/llm_client.dart';
import '../core/spec/day_model.dart';
import '../core/storage/secure.dart';
import '../core/spec/day_repository.dart';
import '../core/storage/app_store.dart';
import '../domain/countdown.dart';
import '../features/reading_mode/reading_aloud.dart';

/// 在 main() 里加载完成后 override。
final storeProvider = Provider<AppStore>((ref) => throw UnimplementedError('storeProvider 未初始化'));

final dayRepositoryProvider = Provider<DayRepository>((ref) => DayRepository());

final dayIndexProvider = FutureProvider<List<DayIndexEntry>>((ref) => ref.watch(dayRepositoryProvider).index());

final dayDataProvider = FutureProvider.family<DayData, int>((ref, day) => ref.watch(dayRepositoryProvider).load(day));

/// 当前训练日；启动时由 main() 根据日期和上次选择确定。
final initialDayProvider = Provider<int>((ref) => 1);

class CurrentDay extends Notifier<int> {
  @override
  int build() => ref.read(initialDayProvider);

  void select(int day) {
    state = day;
    final store = ref.read(storeProvider);
    store.setSetting('lastDay', '$day');
    store.setSetting('lastDayOn', DateTime.now().toIso8601String().substring(0, 10));
  }
}

final currentDayProvider = NotifierProvider<CurrentDay, int>(CurrentDay.new);

/// 「今日」里的四步：0 阅读 1 翻译 2 写作 3 笔记。
class TodayStep extends Notifier<int> {
  @override
  int build() => 0;

  void select(int step) => state = step;
}

final todayStepProvider = NotifierProvider<TodayStep, int>(TodayStep.new);

/// 阅读 A / B。
class ReadingTab extends Notifier<String> {
  @override
  String build() => 'r1';

  void select(String id) => state = id;
}

final readingTabProvider = NotifierProvider<ReadingTab, String>(ReadingTab.new);

final countdownHubProvider = Provider<CountdownHub>((ref) {
  final hub = CountdownHub();
  ref.onDispose(hub.dispose);
  return hub;
});

final readingAloudProvider = Provider<ReadingAloud>((ref) {
  final r = ReadingAloud();
  ref.onDispose(r.dispose);
  return r;
});

/// 生成题包增删、导入备份后调用，让题库与当日数据重新读取。
void refreshDays(WidgetRef ref) {
  ref.invalidate(dayIndexProvider);
  ref.invalidate(dayDataProvider);
}

// ---------------- 模型 API（只在 Keystore） ----------------

final apiConfigStoreProvider = Provider<ApiConfigStore>((ref) => MemoryApiConfigStore());

final initialApiConfigProvider = Provider<ApiConfig>((ref) => ApiConfig.empty);

class ApiConfigNotifier extends Notifier<ApiConfig> {
  @override
  ApiConfig build() => ref.read(initialApiConfigProvider);

  Future<void> save(ApiConfig config) async {
    await ref.read(apiConfigStoreProvider).write(config);
    state = config;
  }

  Future<void> clear() async {
    await ref.read(apiConfigStoreProvider).clear();
    state = ApiConfig.empty;
  }
}

final apiConfigProvider = NotifierProvider<ApiConfigNotifier, ApiConfig>(ApiConfigNotifier.new);

/// 未配置完整时为 null：选词翻译按钮隐藏、生成入口引导去配置。
final chatModelProvider = Provider<ChatModel?>((ref) {
  final config = ref.watch(apiConfigProvider);
  return config.isComplete ? LlmClient(config) : null;
});

/// 监听 [AppStore] 变化的便捷组件。
class StoreBuilder extends ConsumerWidget {
  const StoreBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, AppStore store) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    return ListenableBuilder(listenable: store, builder: (context, _) => builder(context, store));
  }
}
