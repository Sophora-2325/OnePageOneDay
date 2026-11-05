import 'package:flutter/painting.dart';

class SpanMark {
  const SpanMark(this.start, this.end, this.style);

  final int start;
  final int end;
  final TextStyle style;
}

/// 把 [text] 按标记区间切分成 TextSpan；重叠区间的样式按顺序合并（后者覆盖前者）。
List<TextSpan> buildMarkedSpans(String text, List<SpanMark> marks) {
  final valid = marks
      .where((m) => m.start < m.end && m.start >= 0 && m.end <= text.length)
      .toList();
  if (valid.isEmpty) return [TextSpan(text: text)];

  final cuts = <int>{0, text.length};
  for (final m in valid) {
    cuts
      ..add(m.start)
      ..add(m.end);
  }
  final points = cuts.toList()..sort();
  final spans = <TextSpan>[];
  for (var i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    if (a == b) continue;
    TextStyle? style;
    for (final m in valid) {
      if (m.start <= a && m.end >= b) {
        style = style == null ? m.style : style.merge(m.style);
      }
    }
    spans.add(TextSpan(text: text.substring(a, b), style: style));
  }
  return spans;
}
