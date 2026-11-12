import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/backup/backup_service.dart';
import '../../core/storage/app_store.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';

/// 「我的 → 备份与恢复」。整张卡从首屏搬到这里，文案与导出 / 导入行为不变。
class BackupPage extends ConsumerWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('备份与恢复'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s2, AppSpace.page, AppSpace.s8),
        children: [
          BackupCard(store: store, onImported: () => syncAfterImport(ref)),
        ],
      ),
    );
  }
}

class BackupCard extends StatelessWidget {
  const BackupCard({super.key, required this.store, required this.onImported});

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
              child: Text('备份不含任何 API 密钥 · v2 含全部三档进度，可兼容旧版备份',
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
