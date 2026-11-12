import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/profile.dart';
import 'paper_card.dart';

/// 本机预设头像色板。浅 / 深各一套，前景与背景都取自既有语义 token，
/// 保证头像首字在两种主题下都满足 4.5:1 对比度。
class AvatarPalette {
  const AvatarPalette(this.bg, this.fg);

  final Color bg;
  final Color fg;
}

List<AvatarPalette> avatarPalette(Brightness brightness) => brightness == Brightness.light
    ? [
        AvatarPalette(Cet6Colors.light.blueSoft, Cet6Colors.light.blue),
        AvatarPalette(Cet6Colors.light.greenSoft, Cet6Colors.light.green),
        AvatarPalette(Cet6Colors.light.redSoft, Cet6Colors.light.red),
        AvatarPalette(Cet6Colors.light.markerSoft, Cet6Colors.light.ink),
      ]
    : [
        AvatarPalette(Cet6Colors.dark.blueSoft, Cet6Colors.dark.blue),
        AvatarPalette(Cet6Colors.dark.greenSoft, Cet6Colors.dark.green),
        AvatarPalette(Cet6Colors.dark.redSoft, Cet6Colors.dark.red),
        AvatarPalette(Cet6Colors.dark.markerSoft, Cet6Colors.dark.marker),
      ];

/// 昵称首字头像：不读相册、不占本机文件，随备份一起恢复。
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.size = 48});

  final Profile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = avatarPalette(Theme.of(context).brightness);
    final p = palette[profile.avatar.abs() % palette.length];
    return Semantics(
      label: '${profile.displayName} 的头像',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: p.fg.withValues(alpha: 0.25)),
        ),
        child: Text(
          profile.initial,
          style: TextStyle(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w700,
            color: p.fg,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// 「我的」首屏身份卡：身份区 + 四格数据（第 4 格是考试倒计时）。
///
/// 四格统一「大数字 / 小单位 / 下方标签」结构，用 IntrinsicHeight 拉齐高度；
/// 标签最多一行并带完整语义文本，字号放大时省略而不撑破栅格。
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    required this.goalName,
    required this.stats,
    required this.today,
    required this.onEdit,
    required this.onCountdownTap,
  });

  final Profile profile;
  final String goalName;
  final ProfileStats stats;
  final DateTime today;
  final VoidCallback onEdit;
  final VoidCallback onCountdownTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final countdown = countdownCell(daysToExam(profile.examDate, today));
    return PaperCard(
      padding: const EdgeInsets.all(AppSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(profile: profile, size: 48),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.subLine(goalName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: AppType.min, color: c.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s1),
              _EditButton(onTap: onEdit),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatCell(value: '${stats.streak}', unit: '天', label: '连续完成'),
                _StatCell(value: '${stats.done}', unit: '天', label: '已完成', divider: true),
                _StatCell(value: '${stats.currentDay}', unit: '日', label: '当前进度', divider: true),
                _StatCell(
                  value: countdown.value,
                  unit: countdown.unit,
                  label: countdown.label,
                  divider: true,
                  onTap: onCountdownTap,
                  semanticsLabel: '距考试 ${countdown.value}${countdown.unit}，${countdown.label}，点击修改考试日期',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: '编辑个人资料',
      child: SizedBox(
        width: 44,
        height: 44,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            foregroundColor: c.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          child: Text('编辑', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.blue)),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.unit,
    required this.label,
    this.divider = false,
    this.onTap,
    this.semanticsLabel,
  });

  final String value;
  final String unit;
  final String label;
  final bool divider;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // 四格结构完全一致：可点格只多一层 InkWell，不改变高度与文字基线。
    Widget cell = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Container(
        foregroundDecoration: divider
            ? BoxDecoration(border: Border(left: BorderSide(color: c.lineSoft)))
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(text: ' $unit', style: TextStyle(fontSize: 12, color: c.muted)),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            // 第 4 格有「未设考试日 / 更新考试日」这类 5 字长标签，
            // 系统字体放大后会被 ellipsis 截断；统一按格子宽度自适应缩放，
            // 固定高度保证四格标签同一基线、不撑高卡片。
            SizedBox(
              height: 17,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppType.min, color: c.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap != null) {
      cell = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: cell,
      );
    }
    return Expanded(
      child: Semantics(
        label: semanticsLabel ?? '$value$unit，$label',
        button: onTap != null,
        child: cell,
      ),
    );
  }
}
