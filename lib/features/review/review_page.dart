import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/storage/app_store.dart';
import '../../domain/day_summary.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/day_header.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import '../today/draft_field.dart';

class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(currentDayProvider);
    final index = ref.watch(dayIndexProvider).value ?? const [];
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: Text('复盘 · ${dayLabel(day)}')),
      body: StoreBuilder(builder: (context, store) {
        final r = store.peekReview(day);
        final summary = DaySummary.of(store, day);
        final allDays = index.map((e) => e.day).toList();
        final doneDays = store.reviews.where((e) => e.done).map((e) => e.day).toSet();
        final summaries = [for (final d in allDays) DaySummary.of(store, d)];
        return ListView(
          key: ValueKey(day),
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
          children: [
            Row(
              children: [
                Expanded(child: _StatTile(label: '已完成', value: '${doneDays.length}', unit: '天')),
                const SizedBox(width: AppSpace.s3),
                Expanded(child: _StatTile(label: '连续完成', value: '${completionStreak(allDays, doneDays)}', unit: '天')),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: _StatTile(
                    label: '今日阅读',
                    value: summary.readingSubmitted == 0 ? '—' : '${summary.readingScore}/${summary.readingTotal}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s4),
            PaperCard(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('得分趋势', style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      _Legend(color: c.blue, label: '阅读 /10'),
                      const SizedBox(width: AppSpace.s3),
                      _Legend(color: c.green, label: '听读 /8'),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s3),
                  if (summaries.every((s) => !s.started))
                    const EmptyState(icon: Icons.bar_chart, title: '还没有成绩', message: '提交阅读或听读题后，这里按天显示得分。')
                  else
                    SizedBox(height: 150, child: _ScoreChart(summaries: summaries, current: day)),
                  const SizedBox(height: AppSpace.s2),
                  Text('目标：仔细阅读 W2 末 6/10、W4 末 7/10、W6 末 8/10；听读逐步到 7/8。', style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s6),
            _ReviewField(
              title: '错题原因',
              hint: '没找到定位？没看懂同义替换？被干扰项骗了？把定位句抄过来。',
              initial: r?.wrongReason ?? '',
              onChanged: (v) => store.updateReview(day, (x) => x.wrongReason = v),
            ),
            _ReviewField(
              title: '3 个生词 / 表达',
              hint: '例：heighten the urge — 加剧冲动',
              initial: r?.vocab ?? '',
              onChanged: (v) => store.updateReview(day, (x) => x.vocab = v),
            ),
            _ReviewField(
              title: '明日改进点',
              hint: '只写一条最重要的。',
              initial: r?.nextStep ?? '',
              onChanged: (v) => store.updateReview(day, (x) => x.nextStep = v),
            ),
            const SizedBox(height: AppSpace.s2),
            if (r?.done ?? false)
              _DoneBanner(onUndo: () => store.updateReview(day, (x) => x.done = false, debounce: false))
            else
              PrimaryButton(
                label: '标记今日完成',
                icon: Icons.task_alt,
                onPressed: () => _markDone(context, store, day),
              ),
          ],
        );
      }),
    );
  }

  void _markDone(BuildContext context, AppStore store, int day) {
    store.updateReview(day, (x) => x.done = true, debounce: false);
    showToast(context, '${dayLabel(day)} 已完成。明天从下一天继续。');
  }
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.title, required this.hint, required this.initial, required this.onChanged});

  final String title;
  final String hint;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(title),
            DraftField(initial: initial, minLines: 3, hint: hint, onChanged: onChanged),
          ],
        ),
      );
}

class _DoneBanner extends StatelessWidget {
  const _DoneBanner({required this.onUndo});

  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PaperCard(
      color: c.greenSoft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
      child: Row(
        children: [
          Icon(Icons.task_alt, color: c.green),
          const SizedBox(width: AppSpace.s3),
          Expanded(child: Text('今日已完成', style: TextStyle(fontWeight: FontWeight.w700, color: c.green))),
          TextButton(onPressed: onUndo, child: Text('撤销', style: TextStyle(color: c.muted))),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PaperCard(
      padding: const EdgeInsets.all(AppSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 2),
          Text.rich(TextSpan(children: [
            TextSpan(
              text: value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            if (unit != null) TextSpan(text: ' $unit', style: TextStyle(fontSize: 12, color: c.muted)),
          ])),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: context.c.muted)),
        ],
      );
}

/// 每天两根柱：阅读得分率、听读得分率。
class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.summaries, required this.current});

  final List<DaySummary> summaries;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final s in summaries)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Bar(ratio: s.readingTotal == 0 ? 0 : s.readingScore / s.readingTotal, color: c.blue, track: c.lineSoft),
                      const SizedBox(width: 3),
                      _Bar(ratio: s.listeningTotal == 0 ? 0 : s.listeningScore / s.listeningTotal, color: c.green, track: c.lineSoft),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'D${s.day}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: s.day == current ? FontWeight.w700 : FontWeight.w400,
                    color: s.day == current ? c.blue : c.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.ratio, required this.color, required this.track});

  final double ratio;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => Container(
          width: 9,
          height: box.maxHeight,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(2)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 9,
            height: box.maxHeight * ratio.clamp(0, 1),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
        ),
      );
}
