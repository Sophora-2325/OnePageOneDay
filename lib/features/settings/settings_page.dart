import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/backup/backup_service.dart';
import '../../core/storage/app_store.dart';
import '../../core/update/update_checker.dart';
import '../../domain/training_scope.dart';
import '../../ui/components/brand.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/day_header.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import 'training_scope_sheets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final day = ref.watch(currentDayProvider);
    final scope = ref.watch(trainingScopeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: StoreBuilder(builder: (context, store) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
          children: [
            _BackupCard(store: store, onImported: () => syncAfterImport(ref)),
            const SizedBox(height: AppSpace.s4),
            PaperCard(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.shield_outlined, color: c.green),
                    const SizedBox(width: AppSpace.s2),
                    Text('数据流向', style: Theme.of(context).textTheme.titleSmall),
                  ]),
                  const SizedBox(height: AppSpace.s2),
                  _FlowLine(icon: Icons.phone_android, text: '作答、草稿、标注、笔记、复盘：只存在这台手机，五档各自独立保存。'),
                  _FlowLine(icon: Icons.cloud_off_outlined, text: '没有账号、没有云同步、没有埋点；开发者看不到任何数据。'),
                  _FlowLine(icon: Icons.record_voice_over_outlined, text: '朗读使用系统语音引擎，离线可用。'),
                  _FlowLine(
                    icon: Icons.call_made,
                    text: '只有选词翻译和生成题包会联网，且只发往你自己填写的模型地址；不填就完全不联网。',
                  ),
                  _FlowLine(icon: Icons.lock_outline, text: 'API 密钥只在系统密钥库，不进数据库、日志和备份文件。'),
                  _FlowLine(icon: Icons.system_update_outlined, text: '检查更新只在你点击时读取一次 GitHub 上的公开版本号，不带任何个人信息。'),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            const SectionTitle('外观'),
            PaperCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'system', label: Text('跟随系统'), icon: Icon(Icons.brightness_auto_outlined)),
                  ButtonSegment(value: 'light', label: Text('浅色'), icon: Icon(Icons.light_mode_outlined)),
                  ButtonSegment(value: 'dark', label: Text('深色'), icon: Icon(Icons.dark_mode_outlined)),
                ],
                selected: {store.setting('themeMode') ?? 'system'},
                showSelectedIcon: false,
                onSelectionChanged: (s) => store.setSetting('themeMode', s.first),
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            SectionTitle('训练', trailing: Text('备考目标 / 难度只在这里切换', style: TextStyle(fontSize: AppType.min, color: c.muted))),
            PaperCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.flag_outlined, color: c.blue),
                    title: const Text('备考目标'),
                    subtitle: Text('${scope.goalSpec.name} · ${scope.goalSpec.sub} · 预置 ${scope.goalSpec.presetDays} 天 · 进度独立'),
                    trailing: Icon(Icons.chevron_right, size: 18, color: c.muted),
                    onTap: () => showGoalSheet(context, ref),
                  ),
                  Divider(height: 1, color: c.lineSoft),
                  ListTile(
                    leading: Icon(Icons.tune_outlined, color: c.blue),
                    title: const Text('档内难度'),
                    subtitle: Text('本套 ${diffLabel(scope.currentDiff)} · 下套 ${diffLabel(scope.nextDiff)}${scope.hasPending ? ' · 待生效' : ''}'),
                    trailing: Icon(Icons.chevron_right, size: 18, color: c.muted),
                    onTap: () => showDifficultySheet(context, ref),
                  ),
                  Divider(height: 1, color: c.lineSoft),
                  ListTile(
                    leading: Icon(Icons.restart_alt, color: c.red),
                    title: Text('重置 ${dayLabel(day)}', style: TextStyle(color: c.red, fontWeight: FontWeight.w600)),
                    subtitle: const Text('清除本日阅读 / 听读作答、草稿和复盘；保留标注与笔记，不影响其他天。'),
                    onTap: () => _confirmReset(context, ref, store, day),
                  ),
                  Divider(height: 1, color: c.lineSoft),
                  Consumer(builder: (context, ref, _) {
                    final cfg = ref.watch(apiConfigProvider);
                    return ListTile(
                      leading: Icon(Icons.api_outlined, color: c.blue),
                      title: const Text('模型 API'),
                      subtitle: Text(cfg.isComplete ? '${cfg.model} · ${cfg.maskedKey}' : '用于选词翻译、生成新的一天；可不填'),
                      trailing: Text(cfg.isComplete ? '已配置' : '未配置',
                          style: TextStyle(fontSize: 12, color: cfg.isComplete ? c.green : c.muted)),
                      onTap: () => context.push('/api'),
                    );
                  }),
                  Divider(height: 1, color: c.lineSoft),
                  ListTile(
                    leading: Icon(Icons.school_outlined, color: c.blue),
                    title: const Text('30 秒教程'),
                    subtitle: const Text('怎么获取密钥、地址和模型名'),
                    onTap: () => context.push('/tutorial'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            const SectionTitle('关于'),
            _AboutCard(goalName: scope.goalSpec.sub),
          ],
        );
      }),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref, AppStore store, int day) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('重置 ${dayLabel(day)}？'),
        content: const Text('将清除本日阅读 / 听读作答、翻译和写作草稿、复盘内容。标注与笔记会保留。此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.c.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重置'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.resetDay(day);
    ref.read(countdownHubProvider).resetDay(store.goal, day);
    if (context.mounted) showToast(context, '${dayLabel(day)} 已重置');
  }
}

class _AboutCard extends StatefulWidget {
  const _AboutCard({required this.goalName});

  final String goalName;

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  String _version = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = p.version);
    });
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final result = await checkForUpdate(currentVersion: _version);
    if (!mounted) return;
    setState(() => _checking = false);
    switch (result) {
      case UpToDate(:final latest):
        showToast(context, '已是最新版本（$latest）');
      case UpdateFailed(:final message, :final network) when network:
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('没连上 GitHub'),
            content: Text('$message\n\n国内网络访问 GitHub 时快时慢，可以过会儿再试，或直接在浏览器里打开发布页看看有没有新版本。',
                style: const TextStyle(height: 1.6)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse(releasesPageUrl), mode: LaunchMode.externalApplication);
                },
                child: const Text('打开发布页'),
              ),
            ],
          ),
        );
      case UpdateFailed(:final message):
        showToast(context, message);
      case UpdateAvailable(:final info):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('发现新版本 ${info.version}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前 $_version${info.published.isEmpty ? '' : ' · 发布于 ${info.published}'}',
                    style: TextStyle(fontSize: 12, color: context.c.muted)),
                const SizedBox(height: AppSpace.s2),
                for (final n in info.notes) Text('· $n', style: const TextStyle(height: 1.6)),
                const SizedBox(height: AppSpace.s3),
                Text('会用浏览器打开 GitHub 下载安装包；本机数据不受影响，建议先导出一份备份。',
                    style: TextStyle(fontSize: 12, height: 1.5, color: context.c.muted)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('以后再说')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse(info.downloadUrl), mode: LaunchMode.externalApplication);
                },
                child: const Text('去下载'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PaperCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const AibiAvatar(size: 48),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(appName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
                    Text(_version.isEmpty ? '每天练一页' : '版本 $_version · 每天练一页',
                        style: TextStyle(fontSize: 12, color: c.muted)),
                  ]),
                ),
              ]),
              const SizedBox(height: AppSpace.s3),
              Text(
                '$mascotName是陪你练完今天这一页的小精灵。当前是${widget.goalName}：2 篇仔细阅读（各 5 题 + 4 道听读题）、'
                '1 段翻译、1 篇写作、笔记与复盘；五档各有材料规范，进度互不影响。'
                '所有文章、题目、译文、范文均为原创仿写，不是真题；听读题不能替代真题听力。',
                style: TextStyle(fontSize: 13, height: 1.6, color: c.inkSoft),
              ),
            ]),
          ),
          Divider(height: 1, color: c.lineSoft),
          // v1.3：去掉 ListTile.leading 造成的第二套左边界，
          // 卡内所有文字统一从 16pt 起排，状态图标移到右侧。
          InkWell(
            onTap: _checking || _version.isEmpty ? null : _check,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('检查更新', style: TextStyle(fontSize: 15, color: c.ink)),
                        const SizedBox(height: 2),
                        Text('手动检查；有新版只提示，不会自动下载',
                            style: TextStyle(fontSize: AppType.min, color: c.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  _checking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.system_update_outlined, color: c.blue, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowLine extends StatelessWidget {
  const _FlowLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.muted),
          const SizedBox(width: AppSpace.s2),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.5, color: c.inkSoft))),
        ],
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({required this.store, required this.onImported});

  final AppStore store;
  final Future<void> Function() onImported;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final last = DateTime.tryParse(store.setting('lastBackupAt') ?? '');
    final stale = last == null || DateTime.now().difference(last).inDays >= 14;
    final lastText = last == null
        ? '从未备份'
        : '上次备份：${last.month} 月 ${last.day} 日 ${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('备份与恢复', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(lastText, style: TextStyle(fontSize: 12, color: stale ? c.red : c.muted)),
            ],
          ),
          const SizedBox(height: AppSpace.s2),
          Text(
            '数据只存在本机：卸载 App、清除数据或换手机都会丢失。定期导出一份备份文件，存到网盘或发给自己。',
            style: TextStyle(fontSize: 13, height: 1.6, color: c.inkSoft),
          ),
          const SizedBox(height: AppSpace.s2),
          Row(children: [
            Icon(Icons.verified_user_outlined, size: 16, color: c.green),
            const SizedBox(width: 4),
            Expanded(
              child: Text('备份不含任何 API 密钥 · v2 含全部五档进度，可兼容旧版备份',
                  style: TextStyle(fontSize: 12, color: c.green, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: AppSpace.s4),
          Row(
            children: [
              Expanded(
                child: OutlineAction(
                  label: '导出',
                  icon: Icons.upload_outlined,
                  onPressed: () async {
                    try {
                      await BackupService(store).export();
                    } catch (e) {
                      if (context.mounted) showToast(context, '导出失败：$e');
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: OutlineAction(
                  label: '导入',
                  icon: Icons.download_outlined,
                  onPressed: () => _import(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final service = BackupService(store);
    try {
      final data = await service.pick();
      if (data == null || !context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入这份备份？'),
          content: Text(
            '${data.summary()}\n\n导入会按记录合并：同一天同一项以备份为准，本机其他数据不会被删除。',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('导入')),
          ],
        ),
      );
      if (ok != true) return;
      await store.importBackup(data);
      await onImported();
      if (context.mounted) showToast(context, '导入完成');
    } on FormatException catch (e) {
      if (context.mounted) showToast(context, '无法导入：${e.message}');
    } catch (e) {
      if (context.mounted) showToast(context, '导入失败：$e');
    }
  }
}
