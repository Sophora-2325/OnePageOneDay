import 'dart:async';

import 'package:flutter/foundation.dart';

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

/// 计时器按「训练日 + 板块」保存在内存中，切换分段不会重置。
class CountdownHub {
  final Map<String, Countdown> _items = {};

  Countdown get(String key, Duration total) => _items.putIfAbsent(key, () => Countdown(total));

  void resetDay(int day) {
    for (final e in _items.entries) {
      if (e.key.startsWith('$day|')) e.value.reset();
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
