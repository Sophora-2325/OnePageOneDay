import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 「今日」四步：阅读 → 翻译 → 写作 → 笔记。
class SegmentedStep extends StatelessWidget {
  const SegmentedStep({
    super.key,
    required this.labels,
    required this.active,
    required this.done,
    required this.onSelect,
  });

  final List<String> labels;
  final int active;
  final List<bool> done;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == active,
                button: true,
                label: '第 ${i + 1} 步 ${labels[i]}${done[i] ? '，已完成' : ''}',
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: i == active ? c.blue : Colors.transparent, width: 2.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StepDot(index: i, active: i == active, done: done[i]),
                        const SizedBox(width: 6),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: i == active ? FontWeight.w700 : FontWeight.w400,
                            color: i == active ? c.blue : c.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.active, required this.done});

  final int index;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final filled = active || done;
    final bg = done && !active ? c.green : c.blue;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? bg : Colors.transparent,
        border: Border.all(color: filled ? bg : c.line),
      ),
      child: done && !active
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : Text(
              '${index + 1}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: filled ? Colors.white : c.muted),
            ),
    );
  }
}
