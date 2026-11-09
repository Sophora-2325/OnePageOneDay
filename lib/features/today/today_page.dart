import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/spec/day_model.dart';
import '../../core/storage/app_store.dart';
import '../../ui/components/brand.dart';
import '../../ui/components/segmented_step.dart';
import '../../ui/components/timer_bar.dart';
import 'notes_step.dart';
import 'reading_step.dart';
import 'translation_step.dart';
import 'writing_step.dart';

const todaySteps = ['阅读', '翻译', '写作', '笔记'];

/// 四步的完成态：阅读 = 两篇都已提交；翻译 / 写作 = 已对照参考；笔记 = 已写内容。
List<bool> stepDone(AppStore store, DayData d) => [
      d.readings.every((r) => store.peekAttempt(d.day, 'reading', r.id)?.submitted ?? false),
      store.flag(store.revealKey(d.day, 'translation')),
      store.flag(store.revealKey(d.day, 'writing')),
      store.note(d.day).trim().isNotEmpty,
    ];

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(currentDayProvider);
    final data = ref.watch(dayDataProvider(day));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: data.when(
                data: (d) => _TodayBody(key: ValueKey(d.day), data: d),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('题目加载失败：$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayBody extends ConsumerWidget {
  const _TodayBody({super.key, required this.data});

  final DayData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(todayStepProvider);
    final rid = ref.watch(readingTabProvider);
    final hub = ref.watch(countdownHubProvider);
    final day = data.day;
    // 四步状态栏统一为「板块 · 时间」两段式；笔记不限时，用 ∞ 占位保持等高。
    // 阅读的「未做 / 已答 / 已提交」不再塞进 label：判分由 ScoreBanner 与四步对勾表达。
    return StoreBuilder(builder: (context, store) {
      final timer = switch (step) {
        0 => TimerBar(
            key: ValueKey('t-r-$rid'),
            countdown: hub.get(store.goal, day, 'reading|$rid', const Duration(minutes: 9)),
            label: data.reading(rid).shortLabel,
          ),
        1 => TimerBar(
            key: const ValueKey('t-t'),
            countdown: hub.get(store.goal, day, 'translation', const Duration(minutes: 25)),
            label: '翻译'),
        2 => TimerBar(
            key: const ValueKey('t-w'),
            countdown: hub.get(store.goal, day, 'writing', const Duration(minutes: 30)),
            label: '写作'),
        _ => const TimerBar(key: ValueKey('t-n'), label: '笔记'),
      };
      return Column(
        children: [
          // 欢迎语与状态栏都在滚动区外、常驻最高位；四步等高，切换不跳动。
          const AibiGreeting(),
          timer,
          Expanded(
            child: IndexedStack(
              index: step,
              children: [
                ReadingStep(data: data),
                TranslationStep(data: data),
                WritingStep(data: data),
                NotesStep(data: data),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// 每个步骤页顶部共用：四步切换。欢迎语已上提到 _TodayBody 的固定区。
class TodayHeader extends ConsumerWidget {
  const TodayHeader({super.key, required this.data});

  final DayData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(todayStepProvider);
    return StoreBuilder(
      builder: (context, store) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.s4),
          SegmentedStep(
            labels: todaySteps,
            active: step,
            done: stepDone(store, data),
            onSelect: ref.read(todayStepProvider.notifier).select,
          ),
          const SizedBox(height: AppSpace.s4),
        ],
      ),
    );
  }
}
