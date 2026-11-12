import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/profile.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import '../../ui/components/profile_card.dart';
import '../../ui/components/setting_row.dart';
import 'settings_actions.dart';

/// 「我的 → 个人资料」。所有字段都只写本机 settings，随备份 v2 一起导出。
/// [focusExamDate] 为 true 时高亮考试日期（从身份卡第 4 格点进来）。
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, this.focusExamDate = false});

  final bool focusExamDate;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _name;
  late int _avatar;
  late ProfileIdentity _identity;
  late DailyGoal _dailyGoal;
  late String _examDate;

  @override
  void initState() {
    super.initState();
    final store = ref.read(storeProvider);
    final p = Profile.fromSettings(store.setting);
    _name = TextEditingController(text: p.nickname);
    _avatar = p.avatar;
    _identity = p.identity;
    _dailyGoal = p.dailyGoal;
    _examDate = p.examDate;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _examText {
    final d = DateTime.tryParse(_examDate);
    return d == null ? '未设置' : '${d.year} 年 ${d.month} 月 ${d.day} 日';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_examDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: '选择考试日期',
    );
    if (picked != null) {
      setState(() => _examDate = _dateKey(picked));
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _save() {
    final store = ref.read(storeProvider);
    final next = Profile(
      nickname: _name.text,
      avatar: _avatar,
      identity: _identity,
      examDate: _examDate,
      dailyGoal: _dailyGoal,
    );
    for (final e in next.toSettings().entries) {
      store.setSetting(e.key, e.value);
    }
    showToast(context, '已保存');
    // 与原型一致：保存后回到「我的」，立刻看到身份卡（含倒计时第 4 格）更新。
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final store = ref.watch(storeProvider);
    final reminder = ReminderSettings.fromSettings(store.setting);
    final palette = avatarPalette(Theme.of(context).brightness);
    final current = Profile(nickname: _name.text, avatar: _avatar);

    return Scaffold(
      appBar: AppBar(title: const Text('个人资料'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s2, AppSpace.page, AppSpace.s8),
        children: [
          PaperCard(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProfileAvatar(profile: current, size: 56),
                    const SizedBox(width: AppSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('头像', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                          const SizedBox(height: 2),
                          Text('本机预设 · 随备份一起恢复',
                              style: TextStyle(fontSize: AppType.min, color: c.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s3),
                Wrap(
                  spacing: AppSpace.s2,
                  children: [
                    for (var i = 0; i < palette.length; i++)
                      _AvatarOption(
                        index: i,
                        palette: palette[i],
                        initial: current.initial,
                        selected: _avatar.abs() % palette.length == i,
                        onTap: () => setState(() => _avatar = i),
                      ),
                  ],
                ),
                const Divider(height: AppSpace.s6),
                const _FieldLabel('昵称'),
                TextField(
                  controller: _name,
                  maxLength: 16,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: '给自己起个名字'),
                ),
                const SizedBox(height: AppSpace.s3),
                const _FieldLabel('备考身份'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ProfileIdentity>(
                    segments: const [
                      ButtonSegment(value: ProfileIdentity.student, label: Text('在校')),
                      ButtonSegment(value: ProfileIdentity.working, label: Text('在职')),
                      ButtonSegment(value: ProfileIdentity.other, label: Text('其他')),
                    ],
                    selected: {_identity},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _identity = s.first),
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                const _FieldLabel('考试日期'),
                Material(
                  color: widget.focusExamDate ? c.blueSoft : c.paper,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(color: widget.focusExamDate ? c.blue : c.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s1),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_examText,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: DateTime.tryParse(_examDate) == null ? c.muted : c.ink)),
                        ),
                        TextButton(
                          onPressed: _pickDate,
                          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                          child: const Text('选择'),
                        ),
                        if (_examDate.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _examDate = ''),
                            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                            child: Text('清除', style: TextStyle(color: c.muted)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.s2),
                Text('留空显示「未设考试日」；按本地日期计算，不出现负数。',
                    style: TextStyle(fontSize: AppType.min, height: 1.5, color: c.muted)),
                const SizedBox(height: AppSpace.s3),
                const _FieldLabel('每日目标'),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<DailyGoal>(
                    segments: const [
                      ButtonSegment(value: DailyGoal.everyDay, label: Text('每天一页')),
                      ButtonSegment(value: DailyGoal.weekdays, label: Text('每周 5 页')),
                      ButtonSegment(value: DailyGoal.custom, label: Text('自定义')),
                    ],
                    selected: {_dailyGoal},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _dailyGoal = s.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          SettingGroup(rows: [
            SettingRow(
              icon: Icons.notifications_none_outlined,
              title: '每日提醒',
              subtitle: reminder.enabled ? '每天 ${reminder.timeLabel} 提醒练一页' : '未开启',
              onTap: () => context.push('/me/reminder'),
            ),
          ]),
          const SizedBox(height: AppSpace.s5),
          PrimaryButton(label: '保存修改', icon: Icons.check, onPressed: _save),
          const SizedBox(height: AppSpace.s3),
          Center(
            child: QuietButton(
              label: '清除个人资料',
              color: c.red,
              onPressed: () async {
                await clearProfileData(context, ref, store);
                if (!mounted) return;
                final p = Profile.fromSettings(store.setting);
                setState(() {
                  _name.text = p.nickname;
                  _avatar = p.avatar;
                  _identity = p.identity;
                  _dailyGoal = p.dailyGoal;
                  _examDate = p.examDate;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.s2),
        child: Text(text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.c.inkSoft)),
      );
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.index,
    required this.palette,
    required this.initial,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final AvatarPalette palette;
  final String initial;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: selected,
      label: '第 ${index + 1} 个头像',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? c.blue : c.line, width: selected ? 2 : 1),
          ),
          child: Text(initial,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: palette.fg)),
        ),
      ),
    );
  }
}
