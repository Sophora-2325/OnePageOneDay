// 定位匹配归一化，与 tools/validate-days.mjs 一致：
// 1. 连续空白折叠成一个空格；2. 弯引号统一为直引号；3. 去掉首尾空白；4. 子串匹配。

const _quoteMap = {
  '\u201C': '"',
  '\u201D': '"',
  '\u2018': "'",
  '\u2019': "'",
};

final _space = RegExp(r'\s');

String normalizeText(String input) => _NormalizedText(input).text.trim();

/// 归一化后的文本，以及每个归一化字符对应的原文下标。
class _NormalizedText {
  _NormalizedText(String source) {
    final buf = StringBuffer();
    var lastWasSpace = false;
    for (var i = 0; i < source.length; i++) {
      final ch = source[i];
      if (_space.hasMatch(ch)) {
        if (lastWasSpace) continue;
        buf.write(' ');
        map.add(i);
        lastWasSpace = true;
        continue;
      }
      buf.write(_quoteMap[ch] ?? ch);
      map.add(i);
      lastWasSpace = false;
    }
    text = buf.toString();
  }

  late final String text;
  final List<int> map = [];
}

/// 在原文 [paragraph] 中查找 [quote]，返回原文字符区间 [start, end)；找不到返回 null。
({int start, int end})? locateRange(String paragraph, String quote) {
  final q = normalizeText(quote);
  if (q.isEmpty) return null;
  final direct = paragraph.indexOf(quote);
  if (direct >= 0) return (start: direct, end: direct + quote.length);

  final n = _NormalizedText(paragraph);
  final at = n.text.indexOf(q);
  if (at < 0) return null;
  final start = n.map[at];
  final end = n.map[at + q.length - 1] + 1;
  return (start: start, end: end);
}

bool quoteInParagraph(String paragraph, String quote) => locateRange(paragraph, quote) != null;
