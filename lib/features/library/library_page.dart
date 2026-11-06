import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/spec/day_model.dart';
import '../../domain/day_summary.dart';
import '../../domain/grading.dart';
import '../../domain/training_scope.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/day_header.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(dayIndexProvider);
    final current = ref.watch(currentDayProvider);
    final scope = ref.watch(trainingScopeProvider);
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: const Text('题库')),
      body: index.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('题库加载失败：$e')),
        data: (days) => StoreBuilder(builder: (context, store) {
          final byWeek = <int, List<DayIndexEntry>>{};
          for (final d in days) {
            byWeek.putIfAbsent(d.week, () => []).add(d);
          }
          final doneCount = days.where((d) => store.peekReview(d.day)?.done ?? false).length;
          final generated = days.where((d) => d.generated).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
            children: [
              Text(
                '${scope.goalSpec.name} · 预置 ${days.length - generated} 天'
                '${generated == 0 ? '' : ' · AI 生成 $generated 天'} · 已完成 $doneCount 天 · 全部离线可用',
                style: TextStyle(fontSize: 13, color: c.muted),
              ),
              const SizedBox(height: AppSpace.s1),
              Text(
                '阅读 ${scope.goalSpec.rule.minWords}–${scope.goalSpec.rule.maxWords} 词 · ${scope.goalSpec.focus}',
                style: TextStyle(fontSize: AppType.min, height: 1.5, color: c.muted),
              ),
              const SizedBox(height: AppSpace.s4),
              for (final week in byWeek.keys.toList()..sort()) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s2),
                  child: Text('第 $week 周', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.blue, letterSpacing: 1)),
                ),
                for (final d in byWeek[week]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.s3),
                    child: _DayTile(
                      entry: d,
                      summary: DaySummary.of(store, d.day),
                      current: d.day == current,
                      onTap: () {
                        ref.read(currentDayProvider.notifier).select(d.day);
                        ref.read(todayStepProvider.notifier).select(0);
                        ref.read(readingTabProvider.notifier).select('r1');
                        context.go('/today');
                      },
                      onLongPress: d.generated ? () => _confirmDelete(context, ref, d, days) : null,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpace.s2),
              const _GenerateCard(),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, DayIndexEntry d, List<DayIndexEntry> days) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除 ${dayLabel(d.day)}？'),
        content: const Text('这是 AI 生成的题包。删除后，这一天的题目以及作答、草稿、标注、笔记、复盘会一并清除，不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.c.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (ref.read(currentDayProvider) == d.day) {
      final presets = days.where((e) => !e.generated).toList();
      ref.read(currentDayProvider.notifier).select(pickDefaultDay(presets, DateTime.now()));
    }
    final store = ref.read(storeProvider);
    await store.deleteGeneratedDay(d.day);
    ref.read(countdownHubProvider).resetDay(store.goal, d.day);
    refreshDays(ref);
    if (context.mounted) showToast(context, '${dayLabel(d.day)} 已删除');
  }
}

class _GenerateCard extends ConsumerWidget {
  const _GenerateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final ready = ref.watch(chatModelProvider) != null;
    final scope = ref.watch(trainingScopeProvider);
    return PaperCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome_outlined, color: c.blue),
            const SizedBox(width: AppSpace.s2),
            Text('生成新的一天', style: Theme.of(context).textTheme.titleSmall),
          ]),
          const SizedBox(height: AppSpace.s2),
          Text(
            ready
                ? '用你自己的模型生成一整天的新题，每段都过质检门禁；不合格不会进入题库。'
                : '填入自己的模型 API 后，可以无限生成新题。不填也能用全部预置题。',
            style: TextStyle(fontSize: 13, height: 1.6, color: c.inkSoft),
          ),
          const SizedBox(height: AppSpace.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: c.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${scope.goalSpec.name} · 将以「${diffLabel(scope.nextDiff)}」难度生成'
                  '${scope.hasPending ? '；下套设置待生效，生成成功后自动复位稳定' : ''}。调整请到「我的」。',
                  style: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          ready
              ? PrimaryButton(label: '开始生成', icon: Icons.auto_awesome, onPressed: () => context.push('/generate'))
              : OutlineAction(label: '配置模型 API', icon: Icons.key_outlined, onPressed: () => context.push('/api')),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.entry, required this.summary, required this.current, required this.onTap, this.onLongPress});

  final DayIndexEntry entry;
  final DaySummary summary;
  final bool current;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: current ? c.blue : c.line, width: current ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s4),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dayLabel(entry.day), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.ink)),
                  Text(formatDayDate(entry.date), style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
              const SizedBox(width: AppSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.theme, style: TextStyle(fontSize: 15, color: c.inkSoft)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pill(
                          summary.readingSubmitted == 0 ? '阅读 未做' : '阅读 ${summary.readingScore}/${summary.readingTotal}',
                          color: summary.readingSubmitted == 2 ? c.green : c.muted,
                        ),
                        _Pill(
                          summary.listeningSubmitted == 0 ? '听读 未做' : '听读 ${summary.listeningScore}/${summary.listeningTotal}',
                          color: summary.listeningSubmitted == 2 ? c.green : c.muted,
                        ),
                        if (entry.generated) _Pill('AI 生成 · 长按删除', color: c.blue),
                        if (current) _Pill('当前', color: c.blue),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                summary.done ? Icons.check_circle : Icons.chevron_right,
                color: summary.done ? c.green : c.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text, style: TextStyle(fontSize: AppType.min, color: color, fontWeight: FontWeight.w600)),
      );
}
