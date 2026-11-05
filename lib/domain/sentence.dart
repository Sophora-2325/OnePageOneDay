/// 选词翻译只上传「所选词 + 所在原句」：按句末标点取包含选区的那一句。
({String before, String word, String after}) sentenceAround(String text, int start, int end) {
  final enders = RegExp(r'[.!?。！？]["”’)]?\s');
  var s = 0;
  for (final m in enders.allMatches(text)) {
    if (m.end <= start) {
      s = m.end;
    } else {
      break;
    }
  }
  var e = text.length;
  final tail = enders.firstMatch(text.substring(end));
  if (tail != null) e = end + tail.end;
  return (
    before: text.substring(s, start).trimLeft(),
    word: text.substring(start, end),
    after: text.substring(end, e).trimRight(),
  );
}
