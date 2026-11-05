import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/countdown.dart';

/// 顶部 2px 细进度条 + 右侧计时；超时变红，但不弹窗、不打断。
class TimerBar extends StatelessWidget {
  const TimerBar({super.key, required this.countdown, required this.label});

  final Countdown countdown;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListenableBuilder(
      listenable: countdown,
      builder: (context, _) {
        final color = countdown.overtime ? c.red : c.blue;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: countdown.progress,
                color: color,
                backgroundColor: c.lineSoft,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page - 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 13, color: c.muted)),
                  Text(' · ', style: TextStyle(color: c.muted)),
                  Text(
                    countdown.overtime ? '超时 ${formatClock(-countdown.remaining)}' : formatClock(countdown.remaining),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: countdown.overtime ? c.red : c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: countdown.running ? '暂停计时' : '开始计时',
                    onPressed: countdown.toggle,
                    icon: Icon(countdown.running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: c.blue),
                  ),
                  IconButton(
                    tooltip: '重置计时',
                    onPressed: countdown.reset,
                    icon: Icon(Icons.replay_rounded, size: 20, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
