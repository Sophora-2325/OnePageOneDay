import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/update/update_checker.dart';
import '../../ui/components/brand.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';

/// 「我的 → 关于一页英语」。原首屏关于卡整块搬入，检查更新逻辑不变。
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalName = ref.watch(trainingScopeProvider).goalSpec.sub;
    return Scaffold(
      appBar: AppBar(title: const Text('关于一页英语'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s2, AppSpace.page, AppSpace.s8),
        children: [AboutCard(goalName: goalName)],
      ),
    );
  }
}

class AboutCard extends StatefulWidget {
  const AboutCard({super.key, required this.goalName});

  final String goalName;

  @override
  State<AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<AboutCard> {
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
                '1 段翻译、1 篇写作、笔记与复盘；三档各有材料规范，进度互不影响。'
                '所有文章、题目、译文、范文均为原创仿写，不是真题；听读题不能替代真题听力。',
                style: TextStyle(fontSize: 13, height: 1.6, color: c.inkSoft),
              ),
            ]),
          ),
          Divider(height: 1, color: c.lineSoft),
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
