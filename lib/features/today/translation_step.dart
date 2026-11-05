import 'package:flutter/material.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/spec/day_model.dart';
import '../../domain/grading.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import 'draft_field.dart';
import 'today_page.dart';

class TranslationStep extends StatelessWidget {
  const TranslationStep({super.key, required this.data});

  final DayData data;

  @override
  Widget build(BuildContext context) {
    final t = data.translation;
    final c = context.c;
    final day = data.day;
    return StoreBuilder(builder: (context, store) {
      final revealed = store.flag('reveal.$day.translation');
      final checked = store.peekReview(day)?.scoring ?? const <int>{};
      final draft = store.draft(day, 'translation');
      return ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
        children: [
          TodayHeader(data: data),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('TRANSLATION'),
                const SizedBox(height: AppSpace.s2),
                Text('把下面这段话翻译成英文', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpace.s1),
                Text('${countHanzi(t.chinese)} 字 · 日常限时 25 分钟（真题 30 分钟）', style: TextStyle(fontSize: 12, color: c.muted)),
                const SizedBox(height: AppSpace.s3),
                SelectableText(t.chinese, style: TextStyle(fontSize: 16, height: 1.85, color: c.ink)),
                if (t.hints.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s3),
                  Text('提示词', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.muted)),
                  const SizedBox(height: AppSpace.s2),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final h in t.hints) InfoChip(h, serif: true)]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          SectionTitle(
            '我的译文',
            trailing: Text('${countWords(draft)} 词', style: TextStyle(fontSize: 12, color: c.muted)),
          ),
          DraftField(
            initial: draft,
            serif: true,
            hint: '先自己写完，再看参考译文。输入会自动保存在本机。',
            onChanged: (v) => store.setDraft(day, 'translation', v),
          ),
          const SizedBox(height: AppSpace.s4),
          if (!revealed)
            PrimaryButton(
              label: '显示参考译文',
              icon: Icons.visibility_outlined,
              onPressed: () => store.setFlag('reveal.$day.translation', true),
            )
          else ...[
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('REFERENCE'),
                  const SizedBox(height: AppSpace.s2),
                  SelectableText(t.reference, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s4),
            SectionTitle(
              '采分点自评',
              trailing: Text(
                '命中 ${checked.length}/${t.scoringPoints.length}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: checked.length >= (t.scoringPoints.length * 2 / 3).ceil() ? c.green : c.red),
              ),
            ),
            for (var i = 0; i < t.scoringPoints.length; i++)
              ScoringPointTile(
                zh: t.scoringPoints[i].zh,
                en: t.scoringPoints[i].en,
                checked: checked.contains(i),
                onChanged: (on) => store.updateReview(day, (r) => on ? r.scoring.add(i) : r.scoring.remove(i), debounce: false),
              ),
            if (t.highlights.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s2),
              const SectionTitle('可迁移句型'),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final h in t.highlights) InfoChip(h, serif: true)]),
            ],
            const SizedBox(height: AppSpace.s4),
            Text('没翻出来的表达，记进「笔记」，明天开始前读一遍。', style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(height: AppSpace.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: QuietButton(
                label: '收起参考译文',
                icon: Icons.visibility_off_outlined,
                onPressed: () => store.setFlag('reveal.$day.translation', false),
              ),
            ),
          ],
        ],
      );
    });
  }
}
