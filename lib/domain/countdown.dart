import 'dart:async';

import 'package:flutter/foundation.dart';

import 'training_scope.dart';

/// 训练计时：只是节奏提示，超时继续计（显示为负数），不打断作答。
class Countdown extends ChangeNotifier {
  Countdown(this.total);

  final Duration total;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  bool get running => _timer != null;
  Duration get remaining => total - _elapsed;
  bool get overtime => _elapsed > total;
  double get progress => total.inSeconds == 0 ? 1 : (_elapsed.inSeconds / total.inSeconds).clamp(0, 1).toDouble();

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void toggle() => running ? pause() : start();

  void reset() {
    pause();
    _elapsed = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// 计时器按「档 + 训练日 + 板块」保存在内存中，切换分段不会重置。
/// key 必须带档：五档各自有同号训练日，不带档会互相串计时进度。
/// 用方法生成 key 而不是让调用方拼字符串，编译器能保证每处都带 goal。
class CountdownHub {
  final Map<String, Countdown> _items = {};

  Countdown get(GoalId goal, int day, String section, Duration total) =>
      _items.putIfAbsent(_key(goal, day, section), () => Countdown(total));

  String _key(GoalId goal, int day, String section) => '${goal.name}|$day|$section';

  /// 重置当前档本日的所有计时（其他档同号日不受影响）。
  void resetDay(GoalId goal, int day) {
    final prefix = '${goal.name}|$day|';
    for (final e in _items.entries) {
      if (e.key.startsWith(prefix)) e.value.reset();
    }
  }

  void dispose() {
    for (final c in _items.values) {
      c.dispose();
    }
  }
}

String formatClock(Duration d) {
  final neg = d.isNegative;
  final s = d.inSeconds.abs();
  final text = '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  return neg ? '-$text' : text;
}
