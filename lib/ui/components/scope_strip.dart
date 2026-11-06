import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/training_scope.dart';

/// 只读状态条：本套 / 下套难度与当前备考目标。
///
/// 刻意**不提供任何点击**：备考目标与难度的切换入口只存在于「我的」页，
/// 今日 / 题库放这一条只是为了让用户随时能判断调整是否已生效
/// （《备考目标与难度调整计划》§4 第 5 条）。
class ScopeStrip extends ConsumerWidget {
  const ScopeStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(trainingScopeProvider);
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: 7),
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(bottom: BorderSide(color: c.lineSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 14, color: c.muted),
              const SizedBox(width: 6),
              Text('${scope.goalSpec.name} · ${scope.goalSpec.sub}',
                  style: TextStyle(fontSize: AppType.min, fontWeight: FontWeight.w600, color: c.inkSoft)),
              const Spacer(),
              _Cell(label: '本套', value: diffLabel(scope.currentDiff), c: c),
              Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: AppSpace.s2), color: c.line),
              _Cell(label: '下套', value: diffLabel(scope.nextDiff), c: c),
              if (scope.hasPending) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: c.blue),
                  ),
                  child: Text('待生效', style: TextStyle(fontSize: AppType.min, color: c.blue)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '本档材料：阅读 ${scope.goalSpec.rule.minWords}–${scope.goalSpec.rule.maxWords} 词 · ${scope.goalSpec.focus}'
            ' · 调整只在「我的」',
            // v1.3：字号提到 12px 后允许两行，避免说明被截成半句。
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: AppType.min, height: 1.35, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, required this.c});

  final String label;
  final String value;
  final Cet6Colors c;

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          style: TextStyle(fontSize: AppType.min, color: c.muted),
          children: [
            TextSpan(text: '$label '),
            TextSpan(text: value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.inkSoft)),
          ],
        ),
      );
}
