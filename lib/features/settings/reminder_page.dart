import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/notifications/reminder_service.dart';
import '../../core/storage/app_store.dart';
import '../../domain/profile.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import '../../ui/components/setting_row.dart';
import 'settings_actions.dart';

const _presets = <(int, int, String)>[
  (7, 30, '早上通勤前'),
  (12, 30, '午休'),
  (20, 0, '晚间固定时段'),
  (21, 30, '睡前'),
];

/// 「我的 → 每日提醒」。真发本机通知：权限、排程、准点模式、测试通知都在这里。
class ReminderPage extends ConsumerStatefulWidget {
  const ReminderPage({super.key});

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  late ReminderSettings _settings;
  ReminderStatus? _status;

  @override
  void initState() {
    super.initState();
    _settings = ReminderSettings.fromSettings(ref.read(storeProvider).setting);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final s = await ReminderService.status();
    if (mounted) setState(() => _status = s);
  }

  AppStore get _store => ref.read(storeProvider);

  Future<void> _update(ReminderSettings next, {bool forceApply = false}) async {
    if (next.enabled || forceApply) {
      await applyReminderChange(context, ref, _store, next);
    } else {
      for (final e in next.toSettings().entries) {
        _store.setSetting(e.key, e.value);
      }
    }
    if (!mounted) return;
    setState(() => _settings = ReminderSettings.fromSettings(_store.setting));
    await _refresh();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _settings.hour, minute: _settings.minute),
      helpText: '选择提醒时间',
    );
    if (picked == null) return;
    await _update(_settings.copyWith(hour: picked.hour, minute: picked.minute));
  }

  Future<void> _toggleExact(bool on) async {
    if (on && !(_status?.exactAlarmsAllowed ?? false)) {
      final go = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('需要精确闹钟权限'),
              content: const Text(
                'Android 14 起，新装应用默认不能使用精确闹钟。不开这个权限也能提醒，只是可能晚几分钟。'
                '要准点提醒，请到系统设置里允许「闹钟与提醒」。',
                style: TextStyle(height: 1.6),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('用不精确模式')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('去授权')),
              ],
            ),
          ) ??
          false;
      if (go) {
        await ReminderService.requestExactAlarmsPermission();
        await _refresh();
        if (!(_status?.exactAlarmsAllowed ?? false) && mounted) {
          showToast(context, '仍未获得精确闹钟权限，已按不精确模式提醒');
        }
      }
    }
    await _update(_settings.copyWith(exact: on));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('每日提醒'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s2, AppSpace.page, AppSpace.s8),
        children: [
          PaperCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
                  title: Text('每日提醒',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                  subtitle: Text(
                    _settings.enabled ? '每天 ${_settings.timeLabel} 提醒练今天这一页' : '已关闭',
                    style: TextStyle(fontSize: AppType.min, color: c.muted),
                  ),
                  value: _settings.enabled,
                  onChanged: (v) => _update(_settings.copyWith(enabled: v), forceApply: true),
                ),
                Divider(height: 1, color: c.lineSoft),
                SettingRow(
                  icon: Icons.schedule_outlined,
                  title: '提醒时间',
                  value: _settings.timeLabel,
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          PaperCard(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('常用时段', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.inkSoft)),
                const SizedBox(height: AppSpace.s2),
                Wrap(
                  spacing: AppSpace.s2,
                  runSpacing: AppSpace.s2,
                  children: [
                    for (final (h, m, label) in _presets)
                      ChoiceChip(
                        label: Text('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $label'),
                        selected: _settings.hour == h && _settings.minute == m,
                        onSelected: (_) => _update(_settings.copyWith(hour: h, minute: m)),
                        showCheckmark: false,
                        labelStyle: TextStyle(fontSize: 13, color: c.ink),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          const SectionTitle('准点与权限'),
          PaperCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('准点提醒',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                  subtitle: Text('关闭时可能晚几分钟，但不需要额外权限',
                      style: TextStyle(fontSize: AppType.min, color: c.muted)),
                  value: _settings.exact,
                  onChanged: _toggleExact,
                ),
                Divider(height: 1, color: c.lineSoft),
                _StatusLine('通知权限', status == null ? '检查中…' : status.notificationsEnabled ? '已开启' : '未开启',
                    ok: status?.notificationsEnabled),
                _StatusLine('精确闹钟', status == null ? '检查中…' : status.exactAlarmsAllowed ? '已允许' : '未允许',
                    ok: status?.exactAlarmsAllowed),
                _StatusLine('本机排程', status == null ? '检查中…' : status.scheduled ? '已设置' : '未设置',
                    ok: status?.scheduled),
                const SizedBox(height: AppSpace.s2),
                Row(
                  children: [
                    Expanded(
                      child: OutlineAction(
                        label: '测试通知',
                        icon: Icons.notifications_active_outlined,
                        onPressed: () async {
                          final ok = await ReminderService.sendTest();
                          if (!context.mounted) return;
                          showToast(context, ok ? '已发送测试通知' : '发送失败：请检查通知权限');
                          await _refresh();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpace.s2),
                    Expanded(
                      child: OutlineAction(
                        label: '系统设置',
                        icon: Icons.settings_outlined,
                        onPressed: () async {
                          await ReminderService.openAppNotificationSettings();
                          await _refresh();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s2),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          Text('提醒只在本机发出，不经过任何服务器；通知内容不含个人资料。点击通知会回到今日页。',
              style: TextStyle(fontSize: AppType.min, height: 1.6, color: c.muted)),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(this.label, this.value, {this.ok});

  final String label;
  final String value;
  final bool? ok;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = ok == null ? c.muted : ok! ? c.green : c.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: c.inkSoft))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
