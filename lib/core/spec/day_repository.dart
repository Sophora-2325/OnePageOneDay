import 'dart:convert';

import 'package:flutter/services.dart';

import 'day_model.dart';

/// 预置题（随包 assets）+ 生成题包（本地数据库）的统一入口。同号时预置题优先。
class DayRepository {
  DayRepository({AssetBundle? bundle, Map<int, Map<String, dynamic>> Function()? generated})
      : _bundle = bundle ?? rootBundle,
        _generated = generated ?? (() => const {});

  final AssetBundle _bundle;
  final Map<int, Map<String, dynamic>> Function() _generated;
  final Map<int, DayData> _cache = {};
  final Map<int, Map<String, dynamic>> _rawCache = {};
  List<DayIndexEntry>? _presetIndex;

  Future<List<DayIndexEntry>> presetIndex() async {
    if (_presetIndex != null) return _presetIndex!;
    final raw = await _bundle.loadString('assets/days/index.json');
    _presetIndex = (jsonDecode(raw) as List).map((e) => DayIndexEntry.fromJson((e as Map).cast())).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return _presetIndex!;
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

  /// 下一个可用的训练日编号。
  Future<int> nextDayNumber() async {
    final all = await index();
    return all.isEmpty ? 1 : all.map((e) => e.day).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// 预置题的原始 JSON，供生成引擎做 few-shot 示例。
  Future<Map<String, dynamic>> presetRaw(int day) async {
    final cached = _rawCache[day];
    if (cached != null) return cached;
    final entry = (await presetIndex()).firstWhere((e) => e.day == day);
    final raw = await _bundle.loadString('assets/days/${entry.file}');
    return _rawCache[day] = (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<DayData> load(int day) async {
    final cached = _cache[day];
    if (cached != null) return cached;
    if ((await presetIndex()).any((e) => e.day == day)) {
      return _cache[day] = DayData.fromJson(await presetRaw(day));
    }
    final gen = _generated()[day];
    if (gen == null) throw StateError('Day $day 不存在');
    return DayData.fromJson(gen);
  }
}
