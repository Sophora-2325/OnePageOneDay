import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/storage/app_store.dart';
import '../../domain/profile.dart';
import '../../domain/training_scope.dart';
import '../../ui/components/paper_card.dart';
import '../../ui/components/profile_card.dart';
import '../../ui/components/setting_row.dart';
import 'training_scope_sheets.dart';

/// 「我的」首屏：身份卡 → 我的训练 → 通用设置。
/// 原来的备份说明、绿色合规卡、长篇关于文案都收进 /me/* 二级页或下线；
/// 首屏只保留「我是谁 / 练得怎样 / 去哪设置」三层信息。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(currentDayProvider);
    final scope = ref.watch(trainingScopeProvider);
    final cfg = ref.watch(apiConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: true),
      body: StoreBuilder(builder: (context, store) {
        final profile = Profile.fromSettings(store.setting);
        final reminder = ReminderSettings.fromSettings(store.setting);
        final stats = computeProfileStats(store, day);
        final last = DateTime.tryParse(store.setting('lastBackupAt') ?? '');
        final backupValue = last == null ? '从未备份' : '${last.month} 月 ${last.day} 日';

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
          children: [
            const SizedBox(height: AppSpace.s2),
            ProfileCard(
              profile: profile,
              goalName: scope.goalSpec.name,
              stats: stats,
              today: DateTime.now(),
              onEdit: () => context.push('/me/profile'),
              onCountdownTap: () => context.push('/me/profile?exam=1'),
            ),
            const SizedBox(height: AppSpace.s4),
            const SectionTitle('我的训练'),
            SettingGroup(rows: [
              SettingRow(
                icon: Icons.flag_outlined,
                title: '备考目标',
                subtitle: '${scope.goalSpec.name} · ${scope.goalSpec.sub} · 预置 ${scope.goalSpec.presetDays} 天 · 进度独立',
                onTap: () => showGoalSheet(context, ref),
              ),
              SettingRow(
                icon: Icons.tune_outlined,
                title: '档内难度',
                subtitle: '本套 ${diffLabel(scope.currentDiff)} · 下套 ${diffLabel(scope.nextDiff)}${scope.hasPending ? ' · 待生效' : ''}',
                onTap: () => showDifficultySheet(context, ref),
              ),
              SettingRow(
                icon: Icons.api_outlined,
                title: '模型 API',
                subtitle: cfg.isComplete ? '${cfg.model} · ${cfg.maskedKey}' : '用于选词翻译、生成新的一天；可不填',
                value: cfg.isComplete ? '已配置' : '未配置',
                onTap: () => context.push('/api'),
              ),
              SettingRow(
                icon: Icons.school_outlined,
                title: '30 秒教程',
                subtitle: '怎么获取密钥、地址和模型名',
                onTap: () => context.push('/tutorial'),
              ),
            ]),
            const SizedBox(height: AppSpace.s4),
            const SectionTitle('通用设置'),
            SettingGroup(rows: [
              SettingRow(
                icon: Icons.brightness_auto_outlined,
                title: '外观',
                value: themeModeLabel(store.setting('themeMode')),
                onTap: () => showThemeSheet(context, store),
              ),
              SettingRow(
                icon: Icons.notifications_none_outlined,
                title: '每日提醒',
                value: reminder.enabled ? reminder.timeLabel : '未开启',
                onTap: () => context.push('/me/reminder'),
              ),
              SettingRow(
                icon: Icons.backup_outlined,
                title: '备份与恢复',
                value: backupValue,
                onTap: () => context.push('/me/backup'),
              ),
              SettingRow(
                icon: Icons.phone_android_outlined,
                title: '本机数据管理',
                onTap: () => context.push('/me/data'),
              ),
              SettingRow(
                icon: Icons.info_outline,
                title: '关于一页英语',
                trailing: const _VersionValue(),
                onTap: () => context.push('/me/about'),
              ),
            ]),
          ],
        );
      }),
    );
  }
}

String themeModeLabel(String? v) => switch (v) {
      'light' => '浅色',
      'dark' => '深色',
      _ => '跟随系统',
    };

void showThemeSheet(BuildContext context, AppStore store) {
  final current = store.setting('themeMode') ?? 'system';
  const options = <(String, String, IconData)>[
    ('system', '跟随系统', Icons.brightness_auto_outlined),
    ('light', '浅色', Icons.light_mode_outlined),
    ('dark', '深色', Icons.dark_mode_outlined),
  ];
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.c.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s4, AppSpace.page, AppSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('外观', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.s2),
            for (final (value, label, icon) in options)
              ListTile(
                leading: Icon(icon, color: context.c.blue),
                title: Text(label, style: TextStyle(fontSize: 15, color: context.c.ink)),
                trailing: current == value
                    ? Icon(Icons.check, color: context.c.blue)
                    : const SizedBox(width: 24),
                onTap: () {
                  store.setSetting('themeMode', value);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// 关于行的版本号。异步读一次就缓存，避免 ListView 每次重建都重新取。
class _VersionValue extends StatefulWidget {
  const _VersionValue();

  @override
  State<_VersionValue> createState() => _VersionValueState();
}

class _VersionValueState extends State<_VersionValue> {
  late final Future<String> _future = PackageInfo.fromPlatform().then((p) => 'v${p.version}');

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: _future,
        builder: (context, snap) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (snap.hasData)
              Text(snap.data!, style: TextStyle(fontSize: 13, color: context.c.muted)),
            const SizedBox(width: AppSpace.s1),
            Icon(Icons.chevron_right, size: 18, color: context.c.muted),
          ],
        ),
      );
}
