import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/llm_client.dart';
import '../core/notifications/reminder_service.dart';
import '../core/spec/day_model.dart';
import '../core/storage/secure.dart';
import '../core/spec/day_repository.dart';
import '../core/storage/app_store.dart';
import '../domain/countdown.dart';
import '../domain/grading.dart';
import '../domain/profile.dart';
import '../domain/speech_rate.dart';
import '../domain/training_scope.dart';
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
    // 每档各记各的「上次练到哪天」，切档回来接着练。
    store.setSetting(TrainingScope.keyLastDay(store.goal), '$day');
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
  // read 而非 watch：store 是 ChangeNotifier，watch 会让每次记录变更都重建朗读单例。
  final store = ref.read(storeProvider);
  final r = ReadingAloud(
    initialRate: rateFromSetting(store.setting(kTtsRateKey)),
    onRateChanged: (v) => store.setSetting(kTtsRateKey, formatRate(v)),
  );
  ref.onDispose(r.dispose);
  return r;
});

/// 生成题包增删、导入备份后调用，让题库与当日数据重新读取。
void refreshDays(WidgetRef ref) {
  ref.invalidate(dayIndexProvider);
  ref.invalidate(dayDataProvider);
}

/// Notifier 内部持有的是 [Ref] 而不是 [WidgetRef]，单独留一个入口。
void refreshDaysFromRef(Ref ref) {
  ref.invalidate(dayIndexProvider);
  ref.invalidate(dayDataProvider);
}

/// 导入备份后调用：把档位状态、当前训练日、失效的题库与朗读倍速一次性对齐。
/// 定义在文件末尾，运行时才解析 provider，不依赖声明顺序。
Future<void> syncAfterImport(WidgetRef ref) async {
  // 所有 ref 读取都放在第一个 await 之前：导入期间用户可能已经退出设置页。
  final notifier = ref.read(trainingScopeProvider.notifier);
  final store = ref.read(storeProvider);
  final aloud = ref.read(readingAloudProvider);
  await notifier.reloadFromStore();
  await aloud.setRate(rateFromSetting(store.setting(kTtsRateKey)));
  // 备份里带过来的提醒时间 / 开关要立刻反映到系统排程。
  await ReminderService.apply(ReminderSettings.fromSettings(store.setting));
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

// ---------------- 备考目标 / 档内难度 ----------------
// 切换入口只存在于「我的」页：今日、题库、复盘一律 ref.watch 只读展示。

class TrainingScopeNotifier extends Notifier<TrainingScope> {
  @override
  TrainingScope build() => TrainingScope.fromSettings(ref.read(storeProvider).setting);

  void _save(TrainingScope next) {
    final store = ref.read(storeProvider);
    for (final e in next.toSettings().entries) {
      store.setSetting(e.key, e.value);
    }
    state = next;
  }

  /// 只有「我的 → 备考目标」会调用。切档后：换库视图、复位分段、
  /// 并把当前训练日恢复到这一档上次练到的位置（没有记录就取默认日）。
  Future<void> pickGoal(GoalId id) async {
    final next = state.withGoal(id);
    if (next.goal == state.goal) return;
    _save(next);
    await _restoreDay(id);
  }

  /// 导入备份后调用。备份的 settings 可能覆盖 `scope.goal` / 难度，
  /// [AppStore.setSetting] 会改掉 `store.goal`，但 Notifier 只 build 一次，
  /// 不重读就会让 UI 档位、题库与实际数据档不一致。
  Future<void> reloadFromStore() async {
    state = TrainingScope.fromSettings(ref.read(storeProvider).setting);
    await _restoreDay(state.goal);
  }

  /// 切档与导入共用的日号恢复。先写一个本档必定存在的日号，
  /// 避免新题库加载期间读到不存在的 Day。
  Future<void> _restoreDay(GoalId id) async {
    final store = ref.read(storeProvider);
    final repo = ref.read(dayRepositoryProvider);
    // 必须在写入新档的 lastDay 之前读，否则会被临时日号覆盖。
    final last = int.tryParse(store.setting(TrainingScope.keyLastDay(id)) ?? '');
    ref.read(currentDayProvider.notifier).select(1);
    ref.read(todayStepProvider.notifier).select(0);
    ref.read(readingTabProvider.notifier).select('r1');
    refreshDaysFromRef(ref);
    final index = await repo.index();
    // 等题库期间用户可能又切了一次档：放弃这次恢复，
    // 否则会把旧档的日号写进新档的 lastDay（竞态）。
    if (state.goal != id) return;
    final restored = last != null && index.any((e) => e.day == last)
        ? last
        : (index.isEmpty ? 1 : pickDefaultDay(index, DateTime.now()));
    ref.read(currentDayProvider.notifier).select(restored);
  }

  /// 只有「我的 → 档内难度」会调用；只写 nextDiff，不碰本套。
  void setNextDiff(DiffLevel d) => _save(state.withNextDiff(d));

  /// 只在新题包通过质检并成功入库后调用；失败不复位、不消耗调整。
  void settle() => _save(state.settled());
}

final trainingScopeProvider = NotifierProvider<TrainingScopeNotifier, TrainingScope>(TrainingScopeNotifier.new);

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
