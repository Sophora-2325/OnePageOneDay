import 'package:flutter/painting.dart';

/// 把触点坐标换算成段内字符下标。
///
/// 必须与 [SelectableText.rich] 使用同一个 TextStyle 与实际文本宽度，
/// 否则换行位置不同会得到错误下标。系统 TTS 无法从音频第 N 秒 seek，
/// 因此「点哪儿从哪儿读」靠切片后重新合成，这个下标就是切片起点。
int charOffsetAt({
  required String text,
  required TextStyle style,
  required double width,
  required Offset localOffset,
  TextScaler? textScaler,
}) {
  if (text.isEmpty || width <= 0) return 0;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler ?? TextScaler.noScaling,
  )..layout(maxWidth: width);
  final offset = painter.getPositionForOffset(localOffset).offset;
  painter.dispose();
  return offset.clamp(0, text.length);
}
