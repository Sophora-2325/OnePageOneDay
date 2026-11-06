// 切档状态一致性回归：计时器跨档隔离、导入备份后的档位同步、备份版本号。
import 'dart:convert';

import 'package:cet6_app/app/providers.dart';
import 'package:cet6_app/core/backup/backup_codec.dart';
import 'package:cet6_app/core/spec/day_repository.dart';
import 'package:cet6_app/core/storage/app_store.dart';
import 'package:cet6_app/core/storage/db.dart';
import 'package:cet6_app/domain/countdown.dart';
import 'package:cet6_app/domain/training_scope.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 最小题库：所有档都只提供 Day 1，避免测试依赖真机 asset bundle。
class _MemoryBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final text = key.endsWith('index.json')
        ? '[{"day":1,"date":"2026-01-01","week":1,"theme":"t","file":"day-01.json"}]'
        : '{}';
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}

BackupData _backupWithGoal(GoalId goal) => BackupData(
      attempts: const [],
      drafts: const [],
      annotations: const [],
      notes: const [],
      reviews: const [],
      settings: {TrainingScope.keyGoal: goal.name},
    );

void main() {
  test('计时器按档隔离：同号训练日不共用实例，resetDay 不误清别的档', () {
    final hub = CountdownHub();
    addTearDown(hub.dispose);
    const total = Duration(minutes: 9);

    final a = hub.get(GoalId.cet6, 3, 'reading|r1', total);
    final b = hub.get(GoalId.cet4, 3, 'reading|r1', total);
    expect(a, isNot(same(b)), reason: '五档的同号训练日必须是不同计时器');
    expect(hub.get(GoalId.cet6, 3, 'reading|r1', total), same(a), reason: '同档同板块复用');
    expect(hub.get(GoalId.cet6, 3, 'reading|r2', total), isNot(same(a)), reason: 'A/B 篇各自计时');

    a.start();
    b.start();
    hub.resetDay(GoalId.cet6, 3);
    expect(a.running, isFalse);
    expect(b.running, isTrue, reason: '重置六级 Day 3 不应停掉四级 Day 3 的计时');
  });

  test('导入备份后重读设置：档位状态与数据档重新对齐', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = AppStore(db);
    await store.load();
    final repo = DayRepository(
      bundle: _MemoryBundle(),
      goal: () => store.goal,
      generated: () => <int, Map<String, dynamic>>{},
    );
    final container = ProviderContainer(overrides: [
      storeProvider.overrideWithValue(store),
      dayRepositoryProvider.overrideWithValue(repo),
      initialDayProvider.overrideWithValue(1),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    expect(store.goal, GoalId.cet6);
    expect(container.read(trainingScopeProvider).goal, GoalId.cet6);

    await store.importBackup(_backupWithGoal(GoalId.cet4));
    expect(store.goal, GoalId.cet4, reason: '备份 settings 会经 setSetting 改掉数据档');
    expect(container.read(trainingScopeProvider).goal, GoalId.cet6,
        reason: '不重读设置就会残留旧档——修复前的行为');

    await container.read(trainingScopeProvider.notifier).reloadFromStore();
    expect(container.read(trainingScopeProvider).goal, GoalId.cet4);
    expect(container.read(currentDayProvider), 1, reason: '新档只提供 Day 1');
  });

  test('备份元数据可写入真实 App 版本', () {
    expect(_backupWithGoal(GoalId.cet6).appVersion, '1.0.0');
    final tagged = _backupWithGoal(GoalId.cet6).withAppVersion('1.3.0');
    expect(tagged.appVersion, '1.3.0');
    expect(tagged.toJson()['appVersion'], '1.3.0');
  });
}
