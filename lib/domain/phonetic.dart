// 选词翻译结果的音标首行解析（纯 Dart）。
// 模型可能不按格式返回：解析失败时原样展示正文，绝不因首行缺失报错或重试。

final _head = RegExp(r'^\s*[*_`]*\s*音标\s*[*_`]*\s*[:：]\s*');
final _ipa = RegExp(r'/([^/\r\n]+)/');
final _decor = RegExp(r'^[*_`\s]+|[*_`\s]+$');

/// 返回 (音标内容, 正文)。音标缺失或无法识别时音标为 '/—/' 的占位内容，
/// 正文始终是原文去掉音标首行后的剩余部分（信息不丢）。
({String phonetic, String body}) parsePhonetic(String raw) {
  final text = raw.replaceAll('\r\n', '\n').trim();
  if (text.isEmpty) return (phonetic: '—', body: '');

  final lines = text.split('\n');
  final first = lines.first.trim();
  final head = _head.firstMatch(first);
  if (head == null) return (phonetic: '—', body: text);

  final rest = lines.skip(1).join('\n').trim();
  final afterHead = first.substring(head.end);
  final m = _ipa.firstMatch(afterHead);
  if (m == null) {
    return (phonetic: '—', body: _join([_strip(afterHead), rest]));
  }

  final p = m.group(1)!.trim();
  final leftover = _strip(afterHead.substring(m.end));
  return (
    phonetic: (p.isEmpty || p == '—' || p == '-') ? '—' : p,
    body: _join([leftover, rest]),
  );
}

String _strip(String s) => s.replaceAll(_decor, '').trim();

String _join(List<String> parts) => parts.where((s) => s.isNotEmpty).join('\n');
