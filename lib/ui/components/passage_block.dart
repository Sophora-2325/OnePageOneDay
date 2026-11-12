import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/storage/records.dart';
import '../../domain/speech_range.dart';
import '../../domain/tap_offset.dart';
import '../../features/ai/word_translation_sheet.dart';
import 'highlight_spans.dart';
import 'locate_quote.dart';

/// 一段英文正文：定位高亮（黄）、标注下划线（蓝）、朗读中整段底色；
/// 长按选词可「标注」，配置了模型 API 时还可「翻译」。
///
/// 朗读模式额外传 [onTapAt] 时，用最外层 Listener 取触点坐标并换算成
/// 段内字符下标。Listener 不参与手势竞技场，长按选词 / 翻译菜单不受影响。
class PassageBlock extends ConsumerStatefulWidget {
  const PassageBlock({
    super.key,
    required this.paraIndex,
    required this.text,
    this.locateRange,
    this.annotations = const [],
    this.speaking = false,
    this.showNumber = true,
    this.onAnnotate,
    this.onTap,
    this.onTapAt,
    this.speechRange,
  });

  /// 从 0 开始。
  final int paraIndex;
  final String text;
  final ({int start, int end})? locateRange;
  final List<AnnotationRec> annotations;
  final bool speaking;
  final bool showNumber;
  final void Function(int start, int end)? onAnnotate;
  final VoidCallback? onTap;

  /// 短按触点换算出的段内字符下标；只有朗读模式页会传。
  final void Function(int offset)? onTapAt;

  /// 当前朗读选区，用于只染被框定的那一截文字。
  final SpeechRange? speechRange;

  @override
  ConsumerState<PassageBlock> createState() => _PassageBlockState();
}

class _PassageBlockState extends ConsumerState<PassageBlock> {
  final _textKey = GlobalKey();
  Offset? _downPosition;
  Duration? _downStamp;

  TextStyle get _base => Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontSize: 17,
        height: 1.7,
        color: context.c.inkSoft,
      );

  void _onPointerDown(PointerDownEvent event) {
    _downPosition = event.position;
    _downStamp = event.timeStamp;
  }

  void _onPointerUp(PointerUpEvent event) {
    final callback = widget.onTapAt;
    final down = _downPosition;
    final stamp = _downStamp;
    _downPosition = null;
    _downStamp = null;
    if (callback == null || down == null || stamp == null) return;
    // 短按判定：拖动 / 长按选词一律不触发朗读定位。
    // 用指针事件自带的时间戳，而不是系统时钟。
    if ((event.position - down).distance > 8) return;
    if (event.timeStamp - stamp > const Duration(milliseconds: 300)) return;

    final render = _textKey.currentContext?.findRenderObject();
    if (render is! RenderBox || !render.hasSize || render.size.width <= 0) return;
    final local = render.globalToLocal(event.position);
    callback(charOffsetAt(
      text: widget.text,
      style: _base,
      width: render.size.width,
      localOffset: local,
      textScaler: MediaQuery.textScalerOf(context),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final model = ref.watch(chatModelProvider);
    final base = _base;
    final text = widget.text;
    final selection = localRange(widget.speechRange, widget.paraIndex, text);
    final marks = <SpanMark>[
      for (final a in widget.annotations)
        SpanMark(
          a.start,
          a.end,
          TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: c.blue,
            decorationThickness: 2,
            decorationStyle: TextDecorationStyle.dotted,
          ),
        ),
      // 与解析卡的 LocateQuote 共用 markerSoft 实色：深色下 9.02:1，
      // 不再用 marker@60% 半透明叠底（旧实现 3.20:1 且逐行锯齿）。
      if (widget.locateRange != null)
        SpanMark(widget.locateRange!.start, widget.locateRange!.end,
            LocateQuote.inlineStyle(context)),
      // 选区放最后：merge 时后者覆盖前者，优先级高于定位黄与标注点线。
      if (selection != null)
        SpanMark(
          selection.start,
          selection.end,
          TextStyle(
            backgroundColor: c.blue.withValues(
                alpha: Theme.of(context).brightness == Brightness.light
                    ? 0.16
                    : 0.24),
            decoration: TextDecoration.underline,
            decorationColor: c.blue,
            decorationThickness: 2,
          ),
        ),
    ];

    final content = SelectableText.rich(
      TextSpan(style: base, children: buildMarkedSpans(text, marks)),
      onTap: widget.onTap,
      contextMenuBuilder: widget.onAnnotate == null && model == null
          ? null
          : (menuContext, state) {
              final sel = state.textEditingValue.selection;
              final start = sel.start < sel.end ? sel.start : sel.end;
              final end = sel.start < sel.end ? sel.end : sel.start;
              final picked = sel.isValid && !sel.isCollapsed;
              final items = <ContextMenuButtonItem>[
                if (picked && widget.onAnnotate != null)
                  ContextMenuButtonItem(
                    label: '标注',
                    onPressed: () {
                      state.hideToolbar();
                      widget.onAnnotate!(start, end);
                    },
                  ),
                if (picked && model != null)
                  ContextMenuButtonItem(
                    label: '翻译',
                    onPressed: () {
                      state.hideToolbar();
                      showWordTranslation(context, model, text, start, end);
                    },
                  ),
                ...state.contextMenuButtonItems,
              ];
              return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: state.contextMenuAnchors, buttonItems: items);
            },
    );

    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: AppSpace.s3),
      padding: widget.speaking ? const EdgeInsets.all(AppSpace.s2) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: widget.speaking ? c.blueSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showNumber)
            SizedBox(
              width: 18,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('${widget.paraIndex + 1}',
                    style: TextStyle(fontSize: AppType.min, color: c.blue,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          Expanded(child: KeyedSubtree(key: _textKey, child: content)),
        ],
      ),
    );

    return Listener(
      onPointerDown: widget.onTapAt == null ? null : _onPointerDown,
      onPointerUp: widget.onTapAt == null ? null : _onPointerUp,
      child: body,
    );
  }
}

/// 弹出标注编辑框；返回 null 表示取消，返回空串且 [allowDelete] 时表示删除。
Future<String?> showAnnotationEditor(BuildContext context,
    {required String quote, String initial = '', bool allowDelete = false}) {
  final controller = TextEditingController(text: initial);
  final c = context.c;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('标注'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.s2),
              decoration: BoxDecoration(
                color: c.blueSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(quote,
                  style: TextStyle(
                      fontFamily: readingFont, fontSize: 15, color: c.ink)),
            ),
            const SizedBox(height: AppSpace.s3),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '这一处的意思、用法或搭配'),
            ),
            const SizedBox(height: AppSpace.s2),
            Text('标注只保存在本机，绑定这一处原文。',
                style: TextStyle(fontSize: 12, color: c.muted)),
          ],
        ),
      ),
      actions: [
        if (allowDelete)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text('删除', style: TextStyle(color: c.red)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存')),
      ],
    ),
  );
}
