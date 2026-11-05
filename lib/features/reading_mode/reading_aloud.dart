import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 朗读：按段播放系统 TTS，当前段落高亮。
/// 控制器是全局单例，「文章 / 听力题」切换时不会中断。
class ReadingAloud extends ChangeNotifier {
  ReadingAloud() {
    _tts.setCompletionHandler(_onParagraphDone);
    _tts.setErrorHandler((msg) {
      error = '朗读出错：$msg';
      _playing = false;
      notifyListeners();
    });
  }

  final FlutterTts _tts = FlutterTts();
  static const rates = [0.8, 1.0, 1.2];

  String? sourceKey;
  List<String> _paragraphs = const [];
  int currentPara = 0;
  bool _playing = false;
  double rate = 1.0;
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
    await _tts.setSpeechRate(rate * 0.5);
    await _tts.speak(_paragraphs[currentPara]);
  }

  Future<void> pause() async {
    _playing = false;
    notifyListeners();
    await _tts.stop();
  }

  Future<void> toggle() => _playing ? pause() : play();

  Future<void> setRate(double r) async {
    rate = r;
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
