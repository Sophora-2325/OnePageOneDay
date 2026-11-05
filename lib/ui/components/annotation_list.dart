import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/storage/app_store.dart';
import '../../core/storage/records.dart';
import 'passage_block.dart';

String annotationTargetLabel(String target) => switch (target) {
      'r1' => '阅读 A',
      'r2' => '阅读 B',
      'writing' => '范文',
      _ => target,
    };

/// 标注合集：按词分组，展示每一处的出处与备注；点击可编辑或删除。
class AnnotationList extends StatelessWidget {
  const AnnotationList({super.key, required this.store, required this.annotations});

  final AppStore store;
  final List<AnnotationRec> annotations;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (annotations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
        child: Text('还没有标注。在原文或范文里长按选词，点「标注」。', style: TextStyle(color: c.muted, fontSize: 14)),
      );
    }
    final groups = <String, List<AnnotationRec>>{};
    for (final a in annotations) {
      groups.putIfAbsent(a.quote.trim().toLowerCase(), () => []).add(a);
    }
    final keys = groups.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groups[k]!.first.quote.trim(),
                  style: TextStyle(fontFamily: readingFont, fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
                ),
                for (final a in groups[k]!)
                  InkWell(
                    onTap: () async {
                      final result = await showAnnotationEditor(context, quote: a.quote, initial: a.note, allowDelete: true);
                      if (result == null) return;
                      if (result.isEmpty) {
                        store.deleteAnnotation(a);
                      } else {
                        store.updateAnnotation(a, result);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2, right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: c.blueSoft,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'Day ${a.day} · ${annotationTargetLabel(a.target)} · 第 ${a.paraIndex + 1} 段',
                              style: TextStyle(fontSize: 11, color: c.blue),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              a.note.isEmpty ? '（未写备注）' : a.note,
                              style: TextStyle(fontSize: 14, color: a.note.isEmpty ? c.muted : c.inkSoft),
                            ),
                          ),
                          Icon(Icons.edit_outlined, size: 16, color: c.muted),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
