import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/spec/day_model.dart';
import '../../core/storage/app_store.dart';
import '../../ui/components/annotation_list.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/day_header.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import 'draft_field.dart';
import 'today_page.dart';

class NotesStep extends ConsumerWidget {
  const NotesStep({super.key, required this.data});

  final DayData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final day = data.day;
    return StoreBuilder(builder: (context, store) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
        children: [
          TodayHeader(data: data),
          SectionTitle(
            '${dayLabel(day)} 笔记',
            trailing: Text('自动保存在本机', style: TextStyle(fontSize: 12, color: c.muted)),
          ),
          DraftField(
            initial: store.note(day),
            minLines: 10,
            hint: '整理词汇用法、重点句子、错题心得与复习要点……',
            onChanged: (v) => store.setNote(day, v),
          ),
          const SizedBox(height: AppSpace.s3),
          Row(
            children: [
              Expanded(
                child: OutlineAction(
                  label: '保存笔记',
                  icon: Icons.save_outlined,
                  onPressed: () async {
                    await store.flushNote(day);
                    if (context.mounted) showToast(context, '笔记已保存');
                  },
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: OutlineAction(
                  label: '复习以往笔记',
                  icon: Icons.history,
                  onPressed: () => _showPastNotes(context, ref, store),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s6),
          SectionTitle('本日标注合集', trailing: Text('${store.annotationsFor(day).length} 处', style: TextStyle(fontSize: 12, color: c.muted))),
          PaperCard(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: AnnotationList(store: store, annotations: store.annotationsFor(day)),
          ),
          const SizedBox(height: AppSpace.s3),
          Text('标注不会自动堆进笔记；需要的话自己挑重点抄过来。', style: TextStyle(fontSize: 12, color: c.muted)),
        ],
      );
    });
  }

  void _showPastNotes(BuildContext context, WidgetRef ref, AppStore store) {
    final entries = store.notes.values.where((n) => n.body.trim().isNotEmpty).toList()..sort((a, b) => b.day.compareTo(a.day));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, controller) {
          final c = context.c;
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
            children: [
              Text('以往笔记', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpace.s3),
              if (entries.isEmpty)
                const EmptyState(icon: Icons.sticky_note_2_outlined, title: '还没有笔记', message: '学完在「笔记」里按天整理，这里会按日期列出来。'),
              for (final n in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s3),
                  child: PaperCard(
                    padding: const EdgeInsets.all(AppSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(dayLabel(n.day), style: TextStyle(fontWeight: FontWeight.w700, color: c.blue)),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ref.read(currentDayProvider.notifier).select(n.day);
                                ref.read(todayStepProvider.notifier).select(3);
                              },
                              child: const Text('去编辑'),
                            ),
                          ],
                        ),
                        Text(n.body, style: TextStyle(fontSize: 14, height: 1.7, color: c.inkSoft)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
