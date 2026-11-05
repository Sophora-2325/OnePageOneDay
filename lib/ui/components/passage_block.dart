import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/storage/records.dart';
import '../../features/ai/word_translation_sheet.dart';
import 'highlight_spans.dart';

/// 一段英文正文：定位高亮（黄）、标注下划线（蓝）、朗读中整段底色；
/// 长按选词可「标注」，配置了模型 API 时还可「翻译」。
class PassageBlock extends ConsumerWidget {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final model = ref.watch(chatModelProvider);
    final base = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 17, height: 1.7, color: c.inkSoft);
    final marks = <SpanMark>[
      for (final a in annotations)
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
      if (locateRange != null)
        SpanMark(locateRange!.start, locateRange!.end, TextStyle(backgroundColor: c.marker.withValues(alpha: 0.6), color: c.ink)),
    ];

    final content = SelectableText.rich(
      TextSpan(style: base, children: buildMarkedSpans(text, marks)),
      onTap: onTap,
      contextMenuBuilder: onAnnotate == null && model == null
          ? null
          : (menuContext, state) {
              final sel = state.textEditingValue.selection;
              final start = sel.start < sel.end ? sel.start : sel.end;
              final end = sel.start < sel.end ? sel.end : sel.start;
              final picked = sel.isValid && !sel.isCollapsed;
              final items = <ContextMenuButtonItem>[
                if (picked && onAnnotate != null)
                  ContextMenuButtonItem(
                    label: '标注',
                    onPressed: () {
                      state.hideToolbar();
                      onAnnotate!(start, end);
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
              return AdaptiveTextSelectionToolbar.buttonItems(anchors: state.contextMenuAnchors, buttonItems: items);
            },
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: AppSpace.s3),
      padding: speaking ? const EdgeInsets.all(AppSpace.s2) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: speaking ? c.blueSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showNumber)
            SizedBox(
              width: 18,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('${paraIndex + 1}', style: TextStyle(fontSize: 11, color: c.blue, fontWeight: FontWeight.w600)),
              ),
            ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

/// 弹出标注编辑框；返回 null 表示取消，返回空串且 [allowDelete] 时表示删除。
Future<String?> showAnnotationEditor(BuildContext context, {required String quote, String initial = '', bool allowDelete = false}) {
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
              child: Text(quote, style: TextStyle(fontFamily: readingFont, fontSize: 15, color: c.ink)),
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
            Text('标注只保存在本机，绑定这一处原文。', style: TextStyle(fontSize: 12, color: c.muted)),
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
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
      ],
    ),
  );
}
