import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/training_scope.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/misc.dart';

// 「我的」页是备考目标与档内难度的唯一切换入口。
// 这两个 Sheet 只由 settings_page.dart 调用；今日 / 题库 / 复盘不得引用本文件。

/// 五档备考目标，全部可选。每档有独立的预置题包、内容规范与作答进度。
void showGoalSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(trainingScopeProvider).goal;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s4, AppSpace.page, AppSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('选择备考目标', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.s2),
            Text('五档各有自己的材料规范与预置样张，作答、笔记、复盘按档分开保存，切回来接着练。',
                style: TextStyle(fontSize: 13, height: 1.6, color: context.c.muted)),
            const SizedBox(height: AppSpace.s4),
            for (final g in kGoals) _GoalRow(spec: g, current: current, ref: ref, parentContext: context),
            const SizedBox(height: AppSpace.s2),
            Text('切换不打断正在作答的这套题；新题包按本档规范生成。朗读、选词翻译、标注与笔记各档共用。',
                style: TextStyle(fontSize: 12, height: 1.6, color: context.c.muted)),
          ],
        ),
      ),
    ),
  );
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.spec, required this.current, required this.ref, required this.parentContext});

  final GoalSpec spec;
  final GoalId current;
  final WidgetRef ref;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isCurrent = spec.id == current;
    final fg = isCurrent ? c.blue : c.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s2),
      child: Material(
        color: isCurrent ? c.blueSoft : c.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () async {
            if (!spec.ready) {
              showToast(parentContext, '${spec.name}暂未开放');
              return;
            }
            if (isCurrent) {
              Navigator.pop(context);
              return;
            }
            await ref.read(trainingScopeProvider.notifier).pickGoal(spec.id);
            if (parentContext.mounted) {
              showToast(parentContext, '已切到 ${spec.name} · ${spec.sub}，该档进度已恢复');
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: isCurrent ? c.blue : c.line, width: isCurrent ? 1.5 : 1),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 46,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: c.line),
                ),
                alignment: Alignment.center,
                child: Text(spec.mark, style: TextStyle(fontSize: AppType.min, fontWeight: FontWeight.w600, color: fg)),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spec.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                    Text(
                      '${spec.sub} · 预置 ${spec.presetDays} 天 · 阅读 ${spec.rule.minWords}–${spec.rule.maxWords} 词',
                      style: TextStyle(fontSize: AppType.min, color: c.muted),
                    ),
                    Text(spec.focus, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: AppType.min, color: c.muted)),
                  ],
                ),
              ),
              if (isCurrent)
                Icon(Icons.check, size: 20, color: c.blue)
              else
                Icon(Icons.chevron_right, size: 18, color: c.muted),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 档内难度：一次性、延迟生效、本套不变。
void showDifficultySheet(BuildContext pageContext, WidgetRef ref) {
  final scope = ref.read(trainingScopeProvider);
  DiffLevel temp = scope.nextDiff;
  showModalBottomSheet<void>(
    context: pageContext,
    isScrollControlled: true,
    backgroundColor: pageContext.c.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final c = context.c;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s4, AppSpace.page, AppSpace.s5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('档内难度', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpace.s2),
                Text('${scope.goalSpec.name} · 本套正在进行中，调整只作用于这一档的下一套新训练。'
                    '标准材料为阅读 ${scope.goalSpec.rule.minWords}–${scope.goalSpec.rule.maxWords} 词。',
                    style: TextStyle(fontSize: 13, height: 1.6, color: c.muted)),
                const SizedBox(height: AppSpace.s4),
                Row(children: [
                  for (final d in DiffLevel.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: d == DiffLevel.values.last ? 0 : AppSpace.s2),
                        child: _DiffOption(
                          level: d,
                          selected: d == temp,
                          onTap: () => setSheetState(() => temp = d),
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: AppSpace.s4),
                _RuleLine('加难 / 变易各生效一次，加载成功后自动回到稳定。', c),
                _RuleLine('正在作答不打断，继续完成当前题目。', c),
                _RuleLine('本套难度：${scope.goalSpec.name} · ${diffLabel(scope.currentDiff)}（保持不变）。', c),
                const SizedBox(height: AppSpace.s3),
                Container(
                  padding: const EdgeInsets.all(AppSpace.s3),
                  decoration: BoxDecoration(
                    color: c.blueSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: c.line),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 13, color: c.inkSoft),
                      children: [
                        const TextSpan(text: '生效预览：下套 '),
                        TextSpan(text: '${scope.goalSpec.name} · ${diffLabel(temp)}', style: TextStyle(color: c.blue, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s4),
                PrimaryButton(
                  label: '保存设置',
                  onPressed: () {
                    ref.read(trainingScopeProvider.notifier).setNextDiff(temp);
                    Navigator.pop(sheetContext);
                    showToast(pageContext, temp == DiffLevel.steady
                        ? '下套已设为稳定 · 将加载标准材料'
                        : '已设下套为「${diffLabel(temp)}」· 本套不受影响');
                  },
                ),
                const SizedBox(height: AppSpace.s2),
                QuietButton(label: '取消', onPressed: () => Navigator.pop(sheetContext)),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.text, this.c);

  final String text;
  final Cet6Colors c;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.s1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('· ', style: TextStyle(fontSize: 13, color: c.muted)),
            Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.7, color: c.inkSoft))),
          ],
        ),
      );
}

class _DiffOption extends StatelessWidget {
  const _DiffOption({required this.level, required this.selected, required this.onTap});

  final DiffLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg, border) = switch (level) {
      DiffLevel.harder => (c.ink, isDark ? c.bg : c.paper, c.ink),
      DiffLevel.steady => (c.blueSoft, c.blue, c.blue),
      DiffLevel.easier => (c.paper, c.muted, c.line),
    };
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Opacity(
        opacity: selected ? 1 : 0.45,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: selected && level == DiffLevel.steady ? 1.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                switch (level) {
                  DiffLevel.harder => Icons.trending_up,
                  DiffLevel.steady => Icons.remove,
                  DiffLevel.easier => Icons.trending_down,
                },
                size: 18,
                color: fg,
              ),
              const SizedBox(height: AppSpace.s1),
              Text(diffLabel(level), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
              // v1.3：弱信息靠字号下限 + 中性色，不再用 80% 不透明度压低对比度。
              Text(diffHint(level), style: TextStyle(fontSize: AppType.min, color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
