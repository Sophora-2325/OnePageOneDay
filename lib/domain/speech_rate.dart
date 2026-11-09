// 朗读倍速（纯 Dart）。UI 上显示的 1.0x 会换算成系统 TTS 的引擎速率：
// 旧版 1.0x = 引擎 0.5；按需求把默认整体放慢 5% 作为新基准，
// 于是新 1.0x = 0.5 × 0.95 = 0.475，UI 区间 0.75–1.25 对应 0.356–0.594。

const double kRateMin = 0.75;
const double kRateMax = 1.25;
const double kRateDefault = 1.0;

/// Settings 表键：全局一份（设备/耳朵偏好，与备考目标无关），随备份 v2 导出。
const String kTtsRateKey = 'tts.rate';

const double kTtsBaseRate = 0.5 * 0.95;

/// 滑块分度：(1.25 - 0.75) / 0.01。
const int kRateDivisions = 50;

double clampRate(double v) {
  if (!v.isFinite) return kRateDefault;
  return v.clamp(kRateMin, kRateMax).toDouble();
}

/// 保留两位小数：滑块与输入框都按 0.01 步长工作，避免浮点噪声进入 UI 与 TTS。
double normalizeRate(double v) => (clampRate(v) * 100).round() / 100;

String formatRate(double v) => normalizeRate(v).toStringAsFixed(2);

double engineRate(double uiRate) => normalizeRate(uiRate) * kTtsBaseRate;

/// 解析用户输入，非法输入返回 null。兼容 "1.2x"、"1，2" 这类常见写法。
double? parseRate(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'[,，]'), '.');
  s = s.replaceAll(RegExp(r'[xX×倍\s]+$'), '').trim();
  if (s.isEmpty) return null;
  final v = double.tryParse(s);
  if (v == null || !v.isFinite) return null;
  return v;
}

/// 从设置里读回；缺失、非法、越界一律收敛到合法值。
double rateFromSetting(String? raw) {
  if (raw == null) return kRateDefault;
  final v = parseRate(raw);
  return v == null ? kRateDefault : normalizeRate(v);
}
