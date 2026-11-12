import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../ui/components/day_header.dart';
import '../../ui/components/setting_row.dart';
import 'settings_actions.dart';

/// 「我的 → 本机数据管理」。只放两项危险操作，都需要二次确认。
/// 原来的绿色合规卡已整体下线，不再有静态合规说明。
class LocalDataPage extends ConsumerWidget {
  const LocalDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(currentDayProvider);
    final store = ref.watch(storeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('本机数据管理'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s2, AppSpace.page, AppSpace.s8),
        children: [
          SettingGroup(rows: [
            SettingRow(
              icon: Icons.restart_alt,
              title: '重置 ${dayLabel(day)}',
              subtitle: '清除本日作答、草稿和复盘；保留标注与笔记',
              subtitleMaxLines: 2,
              danger: true,
              trailing: const SizedBox(width: 18),
              onTap: () => resetCurrentDay(context, ref, store, day),
            ),
            SettingRow(
              icon: Icons.delete_outline,
              title: '清除个人资料',
              subtitle: '昵称、头像、考试日期与目标恢复默认',
              subtitleMaxLines: 2,
              danger: true,
              trailing: const SizedBox(width: 18),
              onTap: () => clearProfileData(context, ref, store),
            ),
          ]),
        ],
      ),
    );
  }
}
