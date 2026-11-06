import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/training_scope.dart';
import 'day_model.dart';

/// 预置题（随包 assets）+ 生成题包（本地数据库）的统一入口。同号时预置题优先。
///
/// v3：全部按当前备考目标隔离。六级沿用 `assets/days/`，其余档读
/// `assets/days/<goal>/`。生成题包由 AppStore 按档过滤后传入，键是逻辑训练日。
class DayRepository {
  DayRepository({
    AssetBundle? bundle,
    Map<int, Map<String, dynamic>> Function()? generated,
    GoalId Function()? goal,
  })  : _bundle = bundle ?? rootBundle,
        _generated = generated ?? (() => const {}),
        _goal = goal ?? (() => GoalId.cet6);

  final AssetBundle _bundle;
  final Map<int, Map<String, dynamic>> Function() _generated;
  final GoalId Function() _goal;

  final Map<String, DayData> _cache = {};
  final Map<String, Map<String, dynamic>> _rawCache = {};
  final Map<String, List<DayIndexEntry>> _presetIndex = {};

  GoalId get goal => _goal();

  /// 六级的资源保持原路径；其余档放在同名子目录。
  String get assetDir => goal == GoalId.cet6 ? 'assets/days' : 'assets/days/${goal.name}';

  Future<List<DayIndexEntry>> presetIndex() async {
    final key = goal.name;
    final cached = _presetIndex[key];
    if (cached != null) return cached;
    final raw = await _bundle.loadString('$assetDir/index.json');
    return _presetIndex[key] = (jsonDecode(raw) as List)
        .map((e) => DayIndexEntry.fromJson((e as Map).cast()))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }

  Future<List<DayIndexEntry>> index() async {
    final presets = await presetIndex();
    final presetDays = presets.map((e) => e.day).toSet();
    final generated = [
      for (final e in _generated().entries)
        if (!presetDays.contains(e.key))
          DayIndexEntry(
            day: e.key,
            date: e.value['date'].toString(),
            week: (e.value['week'] as num?)?.toInt() ?? 1,
            theme: e.value['theme'].toString(),
            file: '',
            generated: true,
          ),
    ];
    return [...presets, ...generated]..sort((a, b) => a.day.compareTo(b.day));
  }

  /// 本档下一个可用的训练日编号。
  Future<int> nextDayNumber() async {
    final all = await index();
    return all.isEmpty ? 1 : all.map((e) => e.day).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// 本档预置题的原始 JSON，供生成引擎做 few-shot 示例。
  Future<Map<String, dynamic>> presetRaw(int day) async {
    final key = '${goal.name}|$day';
    final cached = _rawCache[key];
    if (cached != null) return cached;
    final entry = (await presetIndex()).firstWhere((e) => e.day == day);
    final raw = await _bundle.loadString('$assetDir/${entry.file}');
    return _rawCache[key] = (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<DayData> load(int day) async {
    final key = '${goal.name}|$day';
    final cached = _cache[key];
    if (cached != null) return cached;
    if ((await presetIndex()).any((e) => e.day == day)) {
      return _cache[key] = DayData.fromJson(await presetRaw(day));
    }
    final gen = _generated()[day];
    if (gen == null) throw StateError('${goal.name} Day $day 不存在');
    return _cache[key] = DayData.fromJson(gen);
  }
}
