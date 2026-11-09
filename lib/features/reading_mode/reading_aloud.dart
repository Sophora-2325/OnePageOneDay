import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/speech_rate.dart';

/// 朗读：按段播放系统 TTS，当前段落高亮。
/// 控制器是全局单例，「文章 / 听力题」切换时不会中断。
class ReadingAloud extends ChangeNotifier {
  ReadingAloud({double? initialRate, this.onRateChanged})
      : rate = normalizeRate(initialRate ?? kRateDefault) {
    _tts.setCompletionHandler(_onParagraphDone);
    _tts.setErrorHandler((msg) {
      error = '朗读出错：$msg';
      _playing = false;
      notifyListeners();
    });
  }

  /// 速率变化后写回 Settings。由 provider 注入，保持本类不依赖存储层。
  final ValueChanged<double>? onRateChanged;

  final FlutterTts _tts = FlutterTts();

  String? sourceKey;
  List<String> _paragraphs = const [];
  int currentPara = 0;
  bool _playing = false;
  double rate;
  String? error;
  bool _prepared = false;

  bool get playing => _playing;
  bool isSource(String key) => sourceKey == key;
  int get paragraphCount => _paragraphs.length;

  Future<void> _prepare() async {
    if (_prepared) return;
    _prepared = true;
    try {
      final ok = await _tts.isLanguageAvailable('en-US');
      if (ok == false) {
        error = '系统没有英语语音包：请在「设置 → 文字转语音」安装英语语音数据。';
      }
      await _tts.setLanguage('en-US');
      await _tts.awaitSpeakCompletion(false);
    } catch (e) {
      error = '无法初始化系统朗读：$e';
    }
  }

  /// 绑定一篇文章；换文章时停止之前的朗读。
  void attach(String key, List<String> paragraphs) {
    if (sourceKey == key) return;
    stop();
    sourceKey = key;
    _paragraphs = paragraphs;
    currentPara = 0;
    notifyListeners();
  }

  Future<void> play({int? from}) async {
    await _prepare();
    if (_paragraphs.isEmpty) return;
    if (from != null) currentPara = from.clamp(0, _paragraphs.length - 1);
    _playing = true;
    notifyListeners();
    await _tts.setSpeechRate(engineRate(rate));
    await _tts.speak(_paragraphs[currentPara]);
  }

  Future<void> pause() async {
    _playing = false;
    notifyListeners();
    await _tts.stop();
  }

  Future<void> toggle() => _playing ? pause() : play();

  /// 收敛到 [kRateMin, kRateMax] 的两位小数；无变化时不做任何事，
  /// 避免滑块松手 / 重复导入备份时无谓地重启当前段落。
  Future<void> setRate(double r) async {
    final next = normalizeRate(r);
    if (next == rate) return;
    rate = next;
    onRateChanged?.call(next);
    notifyListeners();
    if (_playing) {
      await _tts.stop();
      await play();
    }
  }

  Future<void> stop() async {
    if (_playing) await _tts.stop();
    _playing = false;
    notifyListeners();
  }

  void _onParagraphDone() {
    if (!_playing) return;
    if (currentPara < _paragraphs.length - 1) {
      currentPara++;
      notifyListeners();
      _tts.speak(_paragraphs[currentPara]);
    } else {
      _playing = false;
      currentPara = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
