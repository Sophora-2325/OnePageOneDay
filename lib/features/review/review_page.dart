import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/storage/app_store.dart';
import '../../domain/day_summary.dart';
import '../../domain/training_scope.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/day_header.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import '../today/draft_field.dart';

/// 复盘页。顶部「按档查看」只是**统计视角**：只读、不写全局目标，
/// 也不允许在别的档里编辑复盘内容（避免把笔记写进错误的目标）。
/// 真正的目标切换入口只有「我的」页。
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  GoalId? _filter;

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(currentDayProvider);
    final currentGoal = ref.watch(trainingScopeProvider).goal;
    final viewGoal = _filter ?? currentGoal;
    final readOnly = viewGoal != currentGoal;
    final c = context.c;

    // 当前训练档改变时，视角自动跟随，不残留上一档。
    ref.listen(trainingScopeProvider, (prev, next) {
      if (prev?.goal != next.goal && _filter != null) setState(() => _filter = null);
    });

    return Scaffold(
      appBar: AppBar(title: Text('复盘 · ${dayLabel(day)}'), centerTitle: true),
      body: StoreBuilder(builder: (context, store) {
        final spec = goalOf(viewGoal);
        final allDays = _daysFor(store, viewGoal);
        final doneDays = store.reviewsFor(viewGoal).where((e) => e.done).map((e) => e.day).toSet();
        final summaries = [for (final d in allDays) DaySummary.of(store, d, goal: viewGoal)];
        final r = store.reviewFor(currentGoal, day);
        final started = summaries.any((s) => s.started);

        return ListView(
          key: ValueKey('$viewGoal|$day'),
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
          children: [
            GoalFilterCard(
              selected: viewGoal,
              onSelect: (id) => setState(() => _filter = id == currentGoal ? null : id),
            ),
            if (readOnly) ...[
              const SizedBox(height: AppSpace.s3),
              PaperCard(
                color: c.blueSoft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
                child: Row(children: [
                  Icon(Icons.visibility_outlined, size: 18, color: c.blue),
                  const SizedBox(width: AppSpace.s2),
                  Expanded(
                    child: Text('正在查看「${spec.name}」的成绩，仅统计。要在这里写复盘，请先到「我的」切换目标。',
                        style: TextStyle(fontSize: 12, height: 1.5, color: c.inkSoft)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: AppSpace.s4),
            // v1.3 空态：三张「0 天 / —」统计卡 + 得分趋势卡 + 孤立图例
            // 合并为一句引导，不再展示假数据；有成绩时才出现统计与图表。
            if (!started)
              PaperCard(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.bar_chart, size: 20, color: c.muted),
                      const SizedBox(width: AppSpace.s2),
                      Text('${spec.name}还没有成绩', style: Theme.of(context).textTheme.titleSmall),
                    ]),
                    const SizedBox(height: AppSpace.s3),
                    Text('提交第一份作答后开始记录',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                    const SizedBox(height: AppSpace.s1),
                    Text('连续天数、得分趋势和错题原因都会在这里出现。',
                        style: TextStyle(fontSize: AppType.min, height: 1.5, color: c.muted)),
                    const SizedBox(height: AppSpace.s3),
                    OutlineAction(
                      label: '去练今天这一页',
                      icon: Icons.arrow_forward_outlined,
                      onPressed: () => context.go('/today'),
                    ),
                  ],
                ),
              )
            else ...[
              StatTileRow(tiles: [
                StatTile(label: '已完成', value: '${doneDays.length}', unit: '天'),
                StatTile(label: '连续完成', value: '${completionStreak(allDays, doneDays)}', unit: '天'),
                StatTile(label: '本档标准', value: '${spec.rule.minWords}', unit: '词/篇起'),
              ]),
              const SizedBox(height: AppSpace.s4),
              PaperCard(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${spec.name} · 得分趋势', style: Theme.of(context).textTheme.titleSmall),
                        const Spacer(),
                        _Legend(color: c.blue, label: '阅读 /10'),
                        const SizedBox(width: AppSpace.s3),
                        _Legend(color: c.green, label: '听读 /8'),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s3),
                    SizedBox(height: 150, child: _ScoreChart(summaries: summaries, current: day)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpace.s6),
            if (!readOnly) ...[
              _ReviewField(
                title: '错题原因',
                hint: '示例：没找到定位句 / 被同义替换绕住了，把定位句抄过来。',
                initial: r?.wrongReason ?? '',
                onChanged: (v) => store.updateReview(day, (x) => x.wrongReason = v),
              ),
              _ReviewField(
                title: '3 个生词 / 表达',
                hint: '示例：heighten the urge — 加剧冲动',
                initial: r?.vocab ?? '',
                onChanged: (v) => store.updateReview(day, (x) => x.vocab = v),
              ),
              _ReviewField(
                title: '明日改进点',
                hint: '示例：只写一条最重要的，比如「先定位再排除干扰项」。',
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
          ],
        );
      }),
    );
  }

  /// 该档需要画柱子的天数：预置样张天数 + 已有记录里出现的最大日号。
  List<int> _daysFor(AppStore store, GoalId goal) {
    final maxRecord = <int>{
      specMaxDays(goal),
      for (final e in store.attemptsFor(goal)) e.day,
      for (final e in store.reviewsFor(goal)) e.day,
      for (final e in store.generatedFor(goal)) e.day,
    }.reduce((a, b) => a > b ? a : b);
    return [for (var d = 1; d <= maxRecord.clamp(1, 60); d++) d];
  }

  int specMaxDays(GoalId goal) => goalOf(goal).presetDays;

  void _markDone(BuildContext context, AppStore store, int day) {
    store.updateReview(day, (x) => x.done = true, debounce: false);
    showToast(context, '${dayLabel(day)} 已完成。明天从下一天继续。');
  }
}

/// 复盘页顶部的档位视角切换卡。只切统计视角、不写全局目标。
/// 「只读」字样下线后，标题行与三档 Chip 一起居中，卡片左右留白对称。
class GoalFilterCard extends StatelessWidget {
  const GoalFilterCard({super.key, required this.selected, required this.onSelect});

  final GoalId selected;
  final ValueChanged<GoalId> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PaperCard(
      padding: const EdgeInsets.all(AppSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_alt_outlined, size: 16, color: c.muted),
              const SizedBox(width: 6),
              Text('按备考目标查看', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpace.s2),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final g in kGoals)
                _GoalChip(
                  label: g.name,
                  selected: g.id == selected,
                  onTap: () => onSelect(g.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.blueSoft : c.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? c.blue : c.line, width: selected ? 1.3 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? c.blue : c.muted)),
      ),
    );
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

/// 三张统计卡等高：以内容最多的「本档标准」（数值 + 单位可能折两行）为准，
/// 取最高卡的自然高度后拉伸其余两张；卡内文字仍顶部对齐，
/// 三张卡的标签与数值落在同一基线上，字号放大时也会一起长高。
class StatTileRow extends StatelessWidget {
  const StatTileRow({super.key, required this.tiles});

  final List<StatTile> tiles;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.s3),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      );
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.unit});

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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()]),
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
          Text(label, style: TextStyle(fontSize: AppType.min, color: context.c.muted)),
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
                    fontSize: AppType.min,
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
