import 'package:flutter/material.dart';

import '../../app/theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // v1.3：主按钮回到「卷面卡片」调性——描边 + 极轻底，不用大面积亮蓝实底。
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          backgroundColor: enabled ? c.blueSoft : c.lineSoft,
          foregroundColor: c.blue,
          disabledForegroundColor: c.muted,
          side: BorderSide(color: enabled ? c.blue : c.lineSoft, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}

class QuietButton extends StatelessWidget {
  const QuietButton({super.key, required this.label, required this.onPressed, this.icon, this.color});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.c.blue;
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18, color: fg),
      label: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
      ),
    );
  }
}

class OutlineAction extends StatelessWidget {
  const OutlineAction({super.key, required this.label, required this.onPressed, this.icon, this.danger = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = danger ? c.red : c.blue;
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: fg,
          side: BorderSide(color: danger ? c.red : c.line, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}
