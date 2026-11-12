import 'package:flutter_tts/flutter_tts.dart';

/// 朗读引擎抽象：把「合成并播放一段文本」与控制器解耦，
/// 既让队列串播可单测，也给日后换音源留一个口。
abstract class SpeechEngine {
  /// 返回 null 表示就绪；否则返回给用户看的错误文案。
  Future<String?> prepare();

  Future<void> setRate(double engineRate);

  Future<void> speak(String text);

  Future<void> stop();

  void setCompletionHandler(void Function() handler);

  void setErrorHandler(void Function(String message) handler);

  void dispose();
}

/// 系统 TTS 实现。全项目只有这里 import flutter_tts。
class FlutterTtsEngine implements SpeechEngine {
  FlutterTtsEngine([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<String?> prepare() async {
    try {
      final ok = await _tts.isLanguageAvailable('en-US');
      if (ok == false) {
        return '系统没有英语语音包：请在「设置 → 文字转语音」安装英语语音数据。';
      }
      await _tts.setLanguage('en-US');
      await _tts.awaitSpeakCompletion(false);
      return null;
    } catch (e) {
      return '无法初始化系统朗读：$e';
    }
  }

  @override
  Future<void> setRate(double engineRate) => _tts.setSpeechRate(engineRate);

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();

  @override
  void setCompletionHandler(void Function() handler) =>
      _tts.setCompletionHandler(handler);

  @override
  void setErrorHandler(void Function(String message) handler) =>
      // 插件的 ErrorHandler 收 dynamic，这里收敛成 String 再交给控制器。
      _tts.setErrorHandler((message) => handler(message.toString()));

  @override
  void dispose() {
    _tts.stop();
  }
}

/// 单测用的假引擎：不碰平台通道，可手动触发片段完成回调。
class FakeSpeechEngine implements SpeechEngine {
  final List<String> spoken = <String>[];
  final List<double> rates = <double>[];
  int stops = 0;
  String? prepareError;
  void Function()? completion;
  void Function(String message)? errorHandler;

  String? get last => spoken.isEmpty ? null : spoken.last;

  @override
  Future<String?> prepare() async => prepareError;

  @override
  Future<void> setRate(double engineRate) async => rates.add(engineRate);

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;

  @override
  void setCompletionHandler(void Function() handler) => completion = handler;

  @override
  void setErrorHandler(void Function(String message) handler) =>
      errorHandler = handler;

  @override
  void dispose() {}

  /// 模拟当前片段播完，驱动控制器推进队列。
  void finishCurrent() => completion?.call();
}
