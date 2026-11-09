import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/countdown.dart';
import 'misc.dart';

/// 顶部 2px 细进度条 + 右侧计时；超时变红，但不弹窗、不打断。
///
/// [countdown] 为空表示「不限时」（笔记步骤）：时间位显示 ∞，进度槽留空，
/// 但两个按钮照常保留，四步状态栏等高、控件位置一致。此时按钮是只读示意 ——
/// 播放键只切换图标，重置键只给一句提示，不产生任何计时数据。
class TimerBar extends StatefulWidget {
  const TimerBar({super.key, required this.label, this.countdown});

  final String label;
  final Countdown? countdown;

  @override
  State<TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<TimerBar> {
  /// 不限时态下播放键的示意状态；与 Countdown 完全无关。
  bool _idleRunning = false;

  @override
  Widget build(BuildContext context) {
    final cd = widget.countdown;
    return cd == null
        ? _bar(context, null)
        : ListenableBuilder(listenable: cd, builder: (context, _) => _bar(context, cd));
  }

  Widget _bar(BuildContext context, Countdown? cd) {
    final c = context.c;
    final infinite = cd == null;
    final overtime = !infinite && cd.overtime;
    final color = overtime ? c.red : c.blue;
    final running = infinite ? _idleRunning : cd.running;
    final clock = infinite
        ? '∞'
        : overtime
            ? '超时 ${formatClock(-cd.remaining)}'
            : formatClock(cd.remaining);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            value: infinite ? 0 : cd.progress,
            color: color,
            backgroundColor: c.lineSoft,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page - 8),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(fontSize: 13, color: c.muted)),
              Text(' · ', style: TextStyle(color: c.muted)),
              Text(
                clock,
                style: TextStyle(
                  // ∞ 的字面高度比数字小，放大一档才与 09:00 视觉等重。
                  fontSize: infinite ? 16 : 13,
                  fontWeight: FontWeight.w700,
                  color: overtime ? c.red : c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: infinite
                    ? (running ? '暂停（示意）' : '开始（示意）')
                    : (running ? '暂停计时' : '开始计时'),
                onPressed: infinite ? () => setState(() => _idleRunning = !_idleRunning) : cd.toggle,
                icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: c.blue),
              ),
              IconButton(
                tooltip: infinite ? '重置（示意）' : '重置计时',
                onPressed: infinite ? () => showToast(context, '笔记不限时，无需重置') : cd.reset,
                icon: Icon(Icons.replay_rounded, size: 20, color: c.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
