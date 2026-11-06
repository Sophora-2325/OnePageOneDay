import 'package:flutter/material.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/spec/day_model.dart';
import '../../domain/grading.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import '../../ui/components/passage_block.dart';
import 'draft_field.dart';
import 'reading_step.dart';
import 'today_page.dart';

class WritingStep extends StatelessWidget {
  const WritingStep({super.key, required this.data});

  final DayData data;

  @override
  Widget build(BuildContext context) {
    final w = data.writing;
    final c = context.c;
    final day = data.day;
    final essay = w.essayParagraphs;
    return StoreBuilder(builder: (context, store) {
      final revealed = store.flag(store.revealKey(day, 'writing'));
      final draft = store.draft(day, 'writing');
      final annotations = store.annotationsFor(day, 'writing');
      return ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
        children: [
          TodayHeader(data: data),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('WRITING'),
                const SizedBox(height: AppSpace.s2),
                Text(w.topic, style: TextStyle(fontFamily: readingFont, fontSize: 21, height: 1.3, color: c.ink)),
                const SizedBox(height: AppSpace.s2),
                Text(w.prompt, style: TextStyle(fontFamily: readingFont, fontSize: 15, height: 1.6, color: c.inkSoft)),
                const SizedBox(height: AppSpace.s3),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final r in w.requirements) InfoChip(r)]),
                if (w.outlineHints.isNotEmpty)
                  FoldSection(
                    title: '审题提示',
                    icon: Icons.lightbulb_outline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final h in w.outlineHints)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('· $h', style: TextStyle(fontSize: 14, height: 1.6, color: c.inkSoft)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          SectionTitle('我的作文', trailing: WordCountChip(count: countWords(draft))),
          DraftField(
            initial: draft,
            serif: true,
            minLines: 12,
            hint: '30 分钟写完，至少 150 词，目标 170–190 词，三段。',
            onChanged: (v) => store.setDraft(day, 'writing', v),
          ),
          const SizedBox(height: AppSpace.s4),
          if (!revealed)
            PrimaryButton(
              label: '显示范文',
              icon: Icons.visibility_outlined,
              onPressed: () => store.setFlag(store.revealKey(day, 'writing'), true),
            )
          else ...[
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Eyebrow('MODEL ESSAY'),
                      const Spacer(),
                      Text('${countWords(w.modelEssay)} 词', style: TextStyle(fontSize: 12, color: c.muted)),
                      TextButton.icon(
                        onPressed: () => showAnnotationSheet(context, store, () => store.annotationsFor(day, 'writing'), '范文 · 标注合集'),
                        icon: Icon(Icons.edit_note, size: 18, color: c.blue),
                        label: Text('标注 ${annotations.length}', style: TextStyle(color: c.blue, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s2),
                  for (var i = 0; i < essay.length; i++)
                    PassageBlock(
                      paraIndex: i,
                      text: essay[i],
                      showNumber: false,
                      annotations: annotations.where((a) => a.paraIndex == i).toList(),
                      onAnnotate: (s, e) => annotateSelection(
                        context,
                        store,
                        day: day,
                        target: 'writing',
                        paraIndex: i,
                        paragraph: essay[i],
                        start: s,
                        end: e,
                      ),
                    ),
                  if (w.translationParagraphs.isNotEmpty)
                    FoldSection(
                      title: '范文译文（中文）',
                      icon: Icons.translate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final p in w.translationParagraphs)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpace.s3),
                              child: Text(p, style: TextStyle(fontSize: 15, height: 1.7, color: c.inkSoft)),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            const SectionTitle('三段结构'),
            for (final s in w.structure)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s2),
                child: PaperCard(
                  padding: const EdgeInsets.all(AppSpace.s3),
                  child: Text(s, style: TextStyle(fontSize: 14, height: 1.6, color: c.inkSoft)),
                ),
              ),
            const SizedBox(height: AppSpace.s2),
            const SectionTitle('可复用表达'),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final e in w.expressions) InfoChip(e, serif: true)]),
            const SizedBox(height: AppSpace.s3),
            Text('抄 3 个能直接搬到下一篇的句型；背结构，不要整篇背。', style: TextStyle(fontSize: 13, color: c.muted)),
            Align(
              alignment: Alignment.centerLeft,
              child: QuietButton(
                label: '收起范文',
                icon: Icons.visibility_off_outlined,
                onPressed: () => store.setFlag(store.revealKey(day, 'writing'), false),
              ),
            ),
          ],
        ],
      );
    });
  }
}
