import 'package:cet6_app/domain/speech_range.dart';
import 'package:cet6_app/domain/speech_rate.dart';
import 'package:cet6_app/features/reading_mode/reading_aloud.dart';
import 'package:cet6_app/features/reading_mode/speech_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _paras = ['Alpha beta', 'Gamma delta', 'Epsilon zeta'];

/// completion 回调里启动的是 async 方法，等几轮微任务让 speak 落地。
Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('整听：从锚点切片，逐片串播到文末', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);

    await aloud.playFromAnchor(const SpeechAnchor(0, 6));
    expect(engine.spoken, ['beta']);
    expect(aloud.chunkCount, 3);
    expect(aloud.currentPara, 0);
    expect(aloud.range?.end, articleEnd(_paras));

    engine.finishCurrent();
    await _settle();
    expect(engine.spoken, ['beta', 'Gamma delta']);
    expect(aloud.currentPara, 1);

    engine.finishCurrent();
    await _settle();
    expect(engine.spoken, ['beta', 'Gamma delta', 'Epsilon zeta']);
    expect(aloud.playing, isTrue);

    engine.finishCurrent();
    await _settle();
    expect(aloud.playing, isFalse);
    expect(engine.spoken, hasLength(3));
    expect(aloud.range, isNotNull, reason: '播完保留范围，方便重听');
  });

  test('精读：跨段区间倒序自动交换，只播框定的部分', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);

    await aloud.playRange(
        const SpeechRange(SpeechAnchor(2, 7), SpeechAnchor(0, 6)));
    expect(aloud.chunkCount, 3);
    expect(engine.spoken, ['beta']);

    engine.finishCurrent();
    await _settle();
    engine.finishCurrent();
    await _settle();
    expect(engine.spoken, ['beta', 'Gamma delta', 'Epsilon']);
  });

  test('没有任何范围时按播放，默认从文章开头读', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);

    await aloud.play();
    expect(engine.spoken, ['Alpha beta']);
    expect(aloud.range?.start, articleStart(_paras));
  });

  test('兼容旧 play(from:)：从该段段首起播', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);

    await aloud.play(from: 1);
    expect(engine.spoken, ['Gamma delta']);
    expect(aloud.currentPara, 1);
    expect(aloud.chunkCount, 2);
  });

  test('变速只重读当前片段，不回到整段或整篇开头', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);
    await aloud.play();
    engine.finishCurrent();
    await _settle();
    expect(engine.spoken.last, 'Gamma delta');

    await aloud.setRate(1.2);
    expect(engine.spoken, ['Alpha beta', 'Gamma delta', 'Gamma delta']);
    expect(engine.rates.last, engineRate(1.2));
    expect(engine.stops, 1);
    expect(aloud.currentPara, 1);
  });

  test('暂停后继续，从当前片段开头重播', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);
    await aloud.play();
    engine.finishCurrent();
    await _settle();

    await aloud.toggle();
    expect(aloud.playing, isFalse);

    await aloud.toggle();
    expect(engine.spoken.last, 'Gamma delta');
    expect(aloud.currentPara, 1);
  });

  test('暂停后收到完成回调不会继续推进队列', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);
    await aloud.play();
    await aloud.pause();

    engine.finishCurrent();
    await _settle();
    expect(engine.spoken, ['Alpha beta']);
    expect(aloud.playing, isFalse);
  });

  test('换文章清空选区与队列', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);
    await aloud.playFromAnchor(const SpeechAnchor(0, 6));
    expect(aloud.range, isNotNull);

    aloud.attach('y', ['Only one']);
    expect(aloud.range, isNull);
    expect(aloud.chunkCount, 0);
    expect(aloud.playing, isFalse);
    expect(aloud.paragraphCount, 1);
    expect(aloud.isSource('y'), isTrue);
  });

  test('相同 sourceKey 的 attach 不会打断正在播放的内容', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);
    await aloud.play();
    aloud.attach('x', _paras);
    expect(aloud.playing, isTrue);
    expect(engine.spoken, ['Alpha beta']);
  });

  test('清除范围停播并复位队列', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);
    await aloud.play();

    aloud.clearRange();
    expect(aloud.playing, isFalse);
    expect(aloud.range, isNull);
    expect(aloud.chunkCount, 0);
    expect(engine.stops, greaterThan(0));
  });

  test('引擎错误与语音包缺失写进 error', () async {
    final engine = FakeSpeechEngine()..prepareError = '没有英语语音包';
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);
    await aloud.play();
    expect(aloud.error, '没有英语语音包');

    engine.errorHandler?.call('boom');
    expect(aloud.error, contains('朗读出错'));
    expect(aloud.playing, isFalse);
  });

  test('重复设置同一倍速不重启朗读', () async {
    final engine = FakeSpeechEngine();
    final aloud = ReadingAloud(engine: engine);
    aloud.attach('x', _paras);
    await aloud.play();
    final before = engine.spoken.length;

    await aloud.setRate(1.0);
    expect(engine.spoken, hasLength(before));
    expect(engine.stops, 0);
  });
}
