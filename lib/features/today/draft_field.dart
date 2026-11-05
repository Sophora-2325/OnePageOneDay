import 'package:flutter/material.dart';

/// 多行输入框：初始值来自本机存储，输入即保存（存储层 300ms 防抖）。
class DraftField extends StatefulWidget {
  const DraftField({
    super.key,
    required this.initial,
    required this.onChanged,
    this.hint,
    this.minLines = 8,
    this.serif = false,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int minLines;
  final bool serif;

  @override
  State<DraftField> createState() => _DraftFieldState();
}

class _DraftFieldState extends State<DraftField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(DraftField old) {
    super.didUpdateWidget(old);
    if (widget.initial != _controller.text && widget.initial != old.initial) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: widget.minLines,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: widget.serif
          ? Theme.of(context).textTheme.bodyLarge
          : Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(hintText: widget.hint),
      onChanged: widget.onChanged,
    );
  }
}
