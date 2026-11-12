import 'package:flutter/foundation.dart';

import '../../domain/speech_range.dart';
import '../../domain/speech_rate.dart';
import 'speech_engine.dart';

/// 朗读控制器：把用户框定的区间展开成文本片段队列，逐片交给引擎合成。
///
/// 「整听」是终点固定为文末的区间，「精读」是起止都由用户点的区间，
/// 两条路径共用 [_playRange] 与同一条串播队列。控制器是全局单例，
/// 切换「文章 / 听力题」标签不会中断朗读。
class ReadingAloud extends ChangeNotifier {
  ReadingAloud({
    double? initialRate,
    this.onRateChanged,
    SpeechEngine? engine,
  })  : rate = normalizeRate(initialRate ?? kRateDefault),
        _engine = engine ?? FlutterTtsEngine() {
    _engine.setCompletionHandler(_onChunkDone);
    _engine.setErrorHandler((msg) {
      error = '朗读出错：$msg';
      _playing = false;
      notifyListeners();
    });
  }

  /// 速率变化后写回 Settings。由 provider 注入，保持本类不依赖存储层。
  final ValueChanged<double>? onRateChanged;

  final SpeechEngine _engine;

  String? sourceKey;
  List<String> _paragraphs = const [];
  List<SpeechChunk> _queue = const [];
  int _queueIndex = 0;

  int currentPara = 0;
  bool _playing = false;
  double rate;
  String? error;
  bool _prepared = false;

  /// 当前朗读区间，供文章页染色。播完仍保留，方便重听。
  SpeechRange? range;

  bool get playing => _playing;
  bool get hasRange => range != null;
  bool isSource(String key) => sourceKey == key;
  int get paragraphCount => _paragraphs.length;
  int get chunkCount => _queue.length;
  SpeechChunk? get currentChunk =>
      _queue.isEmpty ? null : _queue[_queueIndex.clamp(0, _queue.length - 1)];

  Future<void> _prepare() async {
    if (_prepared) return;
    _prepared = true;
    final message = await _engine.prepare();
    if (message != null) error = message;
  }

  /// 绑定一篇文章；换文章时停止朗读并清空选区。
  void attach(String key, List<String> paragraphs) {
    if (sourceKey == key) return;
    stop();
    sourceKey = key;
    _paragraphs = paragraphs;
    currentPara = 0;
    range = null;
    _queue = const [];
    _queueIndex = 0;
    notifyListeners();
  }

  /// 整听：从任意锚点读到全文结尾。
  Future<void> playFromAnchor(SpeechAnchor anchor) =>
      _playRange(SpeechRange(anchor, articleEnd(_paragraphs)));

  /// 精读：播放用户框定的区间（终点在起点之前会自动交换）。
  Future<void> playRange(SpeechRange value) => _playRange(value);

  /// 兼容旧调用：传 from 时从该段段首起播；不传时续播当前片段，
  /// 没有任何范围则默认从文章开头读。
  Future<void> play({int? from}) {
    if (from != null) {
      final p = from.clamp(0, _paragraphs.length - 1);
      return _playRange(SpeechRange(SpeechAnchor(p, 0), articleEnd(_paragraphs)));
    }
    if (_queue.isNotEmpty) return _speakCurrent();
    return _playRange(SpeechRange(articleStart(_paragraphs), articleEnd(_paragraphs)));
  }

  Future<void> _playRange(SpeechRange value) async {
    await _prepare();
    if (_paragraphs.isEmpty) return;
    range = value.ordered;
    _queue = expandRange(_paragraphs, range!);
    _queueIndex = 0;
    if (_queue.isEmpty) {
      _playing = false;
      notifyListeners();
      return;
    }
    currentPara = _queue.first.para;
    await _speakCurrent();
  }

  Future<void> _speakCurrent() async {
    if (_queue.isEmpty) return;
    final chunk = _queue[_queueIndex];
    currentPara = chunk.para;
    _playing = true;
    notifyListeners();
    await _engine.setRate(engineRate(rate));
    await _engine.speak(chunk.text);
  }

  /// 清除选区与队列，回到「未框定」状态。
  void clearRange() {
    range = null;
    _queue = const [];
    _queueIndex = 0;
    currentPara = 0;
    if (_playing) _engine.stop();
    _playing = false;
    notifyListeners();
  }

  Future<void> pause() async {
    _playing = false;
    notifyListeners();
    await _engine.stop();
  }

  Future<void> toggle() => _playing ? pause() : play();

  /// 变速后只重读「当前片段」，不回到整段或整篇开头。
  Future<void> setRate(double r) async {
    final next = normalizeRate(r);
    if (next == rate) return;
    rate = next;
    onRateChanged?.call(next);
    notifyListeners();
    if (_playing && _queue.isNotEmpty) {
      await _engine.stop();
      await _speakCurrent();
    }
  }

  Future<void> stop() async {
    // 状态必须在第一个 await 之前同步复位：attach() 不 await 本方法，
    // 换文章后立刻读 playing 必须已经是 false。
    final wasPlaying = _playing;
    _playing = false;
    notifyListeners();
    if (wasPlaying) await _engine.stop();
  }

  void _onChunkDone() {
    if (!_playing) return;
    if (_queueIndex < _queue.length - 1) {
      _queueIndex++;
      _speakCurrent();
    } else {
      _playing = false;
      _queueIndex = 0;
      currentPara = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }
}
