import 'package:flutter/foundation.dart';

/// 朗读模式：整听从触点读到文末，精读由用户框定起止。
/// 两者共用同一套区间模型 —— 整听只是「终点固定为文末」的精读。
enum SpeechMode { whole, fine }

/// 精读框选的三态（范围确定后进入 done，仍在听但不再等待点击文本）。
enum MarkPhase { idle, awaitStart, awaitEnd, done }

/// 文章中的一个朗读锚点：段落下标 + 段内字符偏移（end 为开区间）。
@immutable
class SpeechAnchor implements Comparable<SpeechAnchor> {
  const SpeechAnchor(this.para, this.offset);

  final int para;
  final int offset;

  @override
  int compareTo(SpeechAnchor other) =>
      para != other.para ? para.compareTo(other.para) : offset.compareTo(other.offset);

  @override
  bool operator ==(Object other) =>
      other is SpeechAnchor && other.para == para && other.offset == offset;

  @override
  int get hashCode => Object.hash(para, offset);

  @override
  String toString() => 'SpeechAnchor($para, $offset)';
}

@immutable
class SpeechRange {
  const SpeechRange(this.start, this.end);

  final SpeechAnchor start;
  final SpeechAnchor end;

  /// 终点落在起点之前时自动交换，用户不需要关心点击顺序。
  SpeechRange get ordered =>
      start.compareTo(end) <= 0 ? this : SpeechRange(end, start);

  @override
  bool operator ==(Object other) =>
      other is SpeechRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// 展开后的一段可合成文本。start/end 是该段内的字符区间，
/// text 是送到 TTS 的实际文本（已 trim，不改变锚点）。
@immutable
class SpeechChunk {
  const SpeechChunk({
    required this.para,
    required this.start,
    required this.end,
    required this.text,
  });

  final int para;
  final int start;
  final int end;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is SpeechChunk &&
      other.para == para &&
      other.start == start &&
      other.end == end &&
      other.text == text;

  @override
  int get hashCode => Object.hash(para, start, end, text);

  @override
  String toString() => 'SpeechChunk(p$para, $start-$end, ${text.length} chars)';
}

SpeechAnchor articleStart(List<String> paragraphs) => const SpeechAnchor(0, 0);

SpeechAnchor articleEnd(List<String> paragraphs) => paragraphs.isEmpty
    ? const SpeechAnchor(0, 0)
    : SpeechAnchor(paragraphs.length - 1, paragraphs.last.length);

/// 把区间展开为逐片合成的文本块：首段从起点到段末、中间段整段、
/// 末段从段首到终点。跨段不设限制；空段与空切片自动跳过。
List<SpeechChunk> expandRange(List<String> paragraphs, SpeechRange range) {
  final r = range.ordered;
  final chunks = <SpeechChunk>[];
  for (var p = r.start.para; p <= r.end.para; p++) {
    if (p < 0 || p >= paragraphs.length) continue;
    final text = paragraphs[p];
    final a = (p == r.start.para ? r.start.offset : 0).clamp(0, text.length);
    final b = (p == r.end.para ? r.end.offset : text.length).clamp(0, text.length);
    if (a >= b) continue;
    final slice = text.substring(a, b).trim();
    if (slice.isEmpty) continue;
    chunks.add(SpeechChunk(para: p, start: a, end: b, text: slice));
  }
  return chunks;
}

/// 把全局区间折算到某一段，供 PassageBlock 只染选中的那一截文字。
({int start, int end})? localRange(SpeechRange? range, int para, String text) {
  if (range == null) return null;
  final r = range.ordered;
  if (para < r.start.para || para > r.end.para) return null;
  final a = (para == r.start.para ? r.start.offset : 0).clamp(0, text.length);
  final b = (para == r.end.para ? r.end.offset : text.length).clamp(0, text.length);
  return a < b ? (start: a, end: b) : null;
}

bool _isAlnum(String s, int i) {
  if (i < 0 || i >= s.length) return false;
  final c = s.codeUnitAt(i);
  return (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
}

/// 词字符：字母数字，或两侧都被字母数字包住的 ' - . ，
/// 这样 don't / well-known / U.S / 3.5 不会被从中间切断，
/// 而句末的句点、逗号仍是标点。
bool _isWordChar(String s, int i) {
  if (i < 0 || i >= s.length) return false;
  if (_isAlnum(s, i)) return true;
  final c = s.codeUnitAt(i);
  if (c == 0x27 || c == 0x2D || c == 0x2E) {
    return _isAlnum(s, i - 1) && _isAlnum(s, i + 1);
  }
  return false;
}

/// 把触点吸附到「词的开头」：点在词中间回退到词首，
/// 点在空白 / 标点上则向后吸到最近的词首，段尾吸到最后一个词首。
int snapToWordStart(String text, int offset) {
  if (text.isEmpty) return 0;
  final i = offset.clamp(0, text.length);
  if (i < text.length && _isWordChar(text, i)) {
    if (_isWordChar(text, i - 1)) {
      var p = i;
      while (p > 0 && _isWordChar(text, p - 1)) {
        p--;
      }
      return p;
    }
    return i;
  }
  var p = i;
  while (p < text.length && !_isWordChar(text, p)) {
    p++;
  }
  if (p < text.length) return p;
  p = text.length;
  while (p > 0 && _isWordChar(text, p - 1)) {
    p--;
  }
  return p;
}

/// 终点吸附到「词的结尾」（开区间），保证点中的那个词会被读完整。
int snapToWordEnd(String text, int offset) {
  if (text.isEmpty) return 0;
  final start = snapToWordStart(text, offset);
  if (start >= text.length) return text.length;
  var p = start;
  while (p < text.length && _isWordChar(text, p)) {
    p++;
  }
  return p;
}
