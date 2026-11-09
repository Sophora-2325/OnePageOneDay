// 备考目标 / 档内难度状态机 + 本次改动涉及的 UI 文件编译冒烟。
//
// 说明：flutter analyze 的 analysis server 在中文路径下会因 LSP 通道 JSON 截断退出，
// 因此用「import 全部改动文件 + 跑单测」的方式做编译级校验。
import 'package:cet6_app/app/providers.dart';
import 'package:cet6_app/domain/training_scope.dart';
import 'package:cet6_app/features/ai/generate_page.dart';
import 'package:cet6_app/features/ai/word_translation_sheet.dart';
import 'package:cet6_app/features/library/library_page.dart';
import 'package:cet6_app/features/reading_mode/reading_mode_page.dart';
import 'package:cet6_app/features/review/review_page.dart';
import 'package:cet6_app/features/settings/settings_page.dart';
import 'package:cet6_app/features/settings/training_scope_sheets.dart';
import 'package:cet6_app/features/today/today_page.dart';
import 'package:cet6_app/features/today/translation_step.dart';
import 'package:cet6_app/features/today/writing_step.dart';
import 'package:cet6_app/ui/components/brand.dart';
import 'package:cet6_app/ui/components/day_header.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('编译冒烟：改动涉及的库都能被解析', () {
    // 只要这些符号存在且类型正确，本文件才能编译通过。
    expect(const TrainingScope().goal, GoalId.cet6);
    expect(kGoals.length, 3);
    expect(kGoals.map((g) => g.id), [GoalId.cet4, GoalId.cet6, GoalId.kaoyan]);
    expect(const AibiGreeting(), isNotNull);
    // 今日页删掉 DayHeader 后，题库 / 笔记 / 复盘仍依赖这两个纯文本工具。
    expect(dayLabel(5), 'Day 05');
    expect(formatDayDate('2026-11-04'), '11 月 4 日 · 周三');
    expect(const SettingsPage(), isNotNull);
    expect(const TodayPage(), isNotNull);
    expect(const LibraryPage(), isNotNull);
    expect(const ReviewPage(), isNotNull);
    expect(const GeneratePage(), isNotNull);
    expect(trainingScopeProvider, isNotNull);
    // 两个 Sheet 是唯一切换入口，留一条编译级引用防止被误删/改坏签名。
    expect(showGoalSheet, isNotNull);
    expect(showDifficultySheet, isNotNull);
    // 朗读控制条与选词翻译弹层：改动文件必须能被单测编译。
    expect(ListeningBar.new, isNotNull);
    expect(showWordTranslation, isNotNull);
    // 翻译 / 写作页移除输入区后，两个页面仍要能编译、签名不变。
    expect(TranslationStep.new, isNotNull);
    expect(WritingStep.new, isNotNull);
  });

  test('设置往返：从本机设置读出再写回，值不变', () {
    final saved = <String, String>{
      TrainingScope.keyGoal: 'cet6',
      TrainingScope.keyCurrentDiff: 'harder',
      TrainingScope.keyNextDiff: 'easier',
    };
    final scope = TrainingScope.fromSettings((k) => saved[k]);
    expect(scope.goal, GoalId.cet6);
    expect(scope.currentDiff, DiffLevel.harder);
    expect(scope.nextDiff, DiffLevel.easier);
    expect(scope.hasPending, isTrue);
    expect(scope.toSettings(), saved);
  });

  test('未知/损坏的设置值回落到安全默认', () {
    final scope = TrainingScope.fromSettings((_) => 'garbage');
    expect(scope.goal, GoalId.cet6);
    expect(scope.currentDiff, DiffLevel.steady);
    expect(scope.nextDiff, DiffLevel.steady);
    expect(scope.hasPending, isFalse);
  });

  test('延迟生效：设置下套只写 nextDiff，绝不碰本套', () {
    const base = TrainingScope(currentDiff: DiffLevel.harder);
    final next = base.withNextDiff(DiffLevel.easier);
    expect(next.currentDiff, DiffLevel.harder);
    expect(next.nextDiff, DiffLevel.easier);
    expect(next.hasPending, isTrue);
    // 原值不可变
    expect(base.nextDiff, DiffLevel.steady);
  });

  test('加载成功后：本套写入实际难度，下套复位稳定', () {
    final settled = const TrainingScope(currentDiff: DiffLevel.harder).withNextDiff(DiffLevel.easier).settled();
    expect(settled.currentDiff, DiffLevel.easier);
    expect(settled.nextDiff, DiffLevel.steady);
    expect(settled.hasPending, isFalse);
  });

  test('v3：三档全部就绪，切档保留难度状态', () {
    expect(kGoals.where((g) => g.ready).length, 3);
    const scope = TrainingScope(currentDiff: DiffLevel.harder, nextDiff: DiffLevel.easier);
    final switched = scope.withGoal(GoalId.kaoyan);
    expect(switched.goal, GoalId.kaoyan);
    expect(switched.currentDiff, DiffLevel.harder);
    expect(switched.nextDiff, DiffLevel.easier);
  });

  test('旧数据的 day 整数原样落在六级，其余档编码互不冲突', () {
    expect(decodeScopedDay(7), (goal: GoalId.cet6, day: 7));
    for (final g in kGoals.map((s) => s.id)) {
      final scoped = encodeScopedDay(g, 7);
      expect(decodeScopedDay(scoped).goal, g);
      expect(decodeScopedDay(scoped).day, 7);
    }
    expect(encodeScopedDay(GoalId.cet6, 7), 7);
    expect(encodeScopedDay(GoalId.cet4, 7), isNot(encodeScopedDay(GoalId.kaoyan, 7)));
  });

  test('已下线档位不可选，但老数据槽位仍正确解码、不串进六级', () {
    // 从设置 / 备份读到的当前档若属于已下线档，一律回落六级。
    expect(goalIdFromKey('tem4'), isNull);
    expect(goalIdFromKey('tem8'), isNull);
    expect(TrainingScope.fromSettings((_) => 'tem8').goal, GoalId.cet6);
    // 切档防线：即使有人绕过 UI 传入历史枚举，也不得把当前档切进去。
    expect(const TrainingScope().withGoal(GoalId.tem8).goal, GoalId.cet6);
    // 老备份记录解码时 goalOf 不能抛异常。
    expect(goalOf(GoalId.tem8), isNotNull);
    // 槽位 3 / 4 仍解码成自己的档与逻辑日，不会变成「六级 Day 30007」。
    for (final slot in [3, 4]) {
      final decoded = decodeScopedDay(slot * kDayStride + 7);
      expect(decoded.day, 7);
      expect(decoded.goal, isNot(GoalId.cet6));
    }
  });

  test('稳定档不往生成提示词里追加任何约束', () {
    expect(diffPromptNote(DiffLevel.steady), isEmpty);
    expect(diffPromptNote(DiffLevel.harder), contains('加难'));
    expect(diffPromptNote(DiffLevel.easier), contains('变易'));
  });
}
