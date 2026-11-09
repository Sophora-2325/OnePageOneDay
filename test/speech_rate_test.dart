import 'package:cet6_app/domain/speech_rate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('倍速换算', () {
    test('新 1.0x = 引擎 0.475（旧 0.5 放慢 5%）', () {
      expect(kTtsBaseRate, closeTo(0.475, 1e-12));
      expect(engineRate(kRateDefault), closeTo(0.475, 1e-12));
      expect(engineRate(kRateMin), closeTo(0.35625, 1e-12));
      expect(engineRate(kRateMax), closeTo(0.59375, 1e-12));
    });

    test('越界自动收敛到 0.75 / 1.25', () {
      expect(normalizeRate(0.5), kRateMin);
      expect(normalizeRate(2.0), kRateMax);
      expect(normalizeRate(-10), kRateMin);
      expect(clampRate(double.infinity), kRateDefault);
      expect(clampRate(double.nan), kRateDefault);
    });

    test('保留两位小数，避免浮点噪声', () {
      expect(normalizeRate(1.234), 1.23);
      expect(normalizeRate(0.876), 0.88);
      expect(formatRate(1.0), '1.00');
      expect(formatRate(1.25), '1.25');
      expect(formatRate(9), '1.25');
    });
  });

  group('输入框解析', () {
    test('常规小数、带 x 后缀、全角逗号', () {
      expect(parseRate('1.13'), 1.13);
      expect(parseRate(' 1.2x '), 1.2);
      expect(parseRate('1，2'), 1.2);
      expect(parseRate('0.75'), 0.75);
    });

    test('非法输入返回 null，交给 UI 保留上一档', () {
      expect(parseRate(''), isNull);
      expect(parseRate('abc'), isNull);
      expect(parseRate('  '), isNull);
      expect(parseRate('Infinity'), isNull);
      expect(parseRate('NaN'), isNull);
    });
  });

  group('设置读回', () {
    test('缺失 / 非法 / 越界都收敛到合法值', () {
      expect(rateFromSetting(null), kRateDefault);
      expect(rateFromSetting(''), kRateDefault);
      expect(rateFromSetting('oops'), kRateDefault);
      expect(rateFromSetting('2.0'), kRateMax);
      expect(rateFromSetting('0.1'), kRateMin);
      expect(rateFromSetting('1.13'), 1.13);
    });
  });
}
