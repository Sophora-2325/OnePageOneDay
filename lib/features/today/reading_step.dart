import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/spec/day_model.dart';
import '../../core/spec/normalize.dart';
import '../../core/storage/app_store.dart';
import '../../core/storage/records.dart';
import '../../domain/grading.dart';
import '../../ui/components/annotation_list.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import '../../ui/components/passage_block.dart';
import '../../ui/components/question_card.dart';
import 'today_page.dart';

typedef LocateTarget = ({int para, int start, int end});

/// 计算某题在原文中的定位区间；匹配失败时降级为整段高亮。
LocateTarget locateFor(Reading reading, Question q) {
  final p = (q.locatePara - 1).clamp(0, reading.paragraphs.length - 1);
  final text = reading.paragraphs[p];
  final r = locateRange(text, q.locateQuote);
  return r == null ? (para: p, start: 0, end: text.length) : (para: p, start: r.start, end: r.end);
}

Future<void> annotateSelection(
  BuildContext context,
  AppStore store, {
  required int day,
  required String target,
  required int paraIndex,
  required String paragraph,
  required int start,
  required int end,
}) async {
  final quote = paragraph.substring(start, end).trim();
  if (quote.isEmpty) return;
  final note = await showAnnotationEditor(context, quote: quote);
  if (note == null) return;
  await store.addAnnotation(AnnotationRec(
    day: day,
    target: target,
    paraIndex: paraIndex,
    start: start,
    end: end,
    quote: quote,
    note: note,
  ));
  if (context.mounted) showToast(context, '已标注「$quote」');
}

void showAnnotationSheet(BuildContext context, AppStore store, List<AnnotationRec> Function() items, String title) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, controller) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.s3),
            AnnotationList(store: store, annotations: items()),
          ],
        ),
      ),
    ),
  );
}

class ReadingStep extends ConsumerStatefulWidget {
  const ReadingStep({super.key, required this.data});

  final DayData data;

  @override
  ConsumerState<ReadingStep> createState() => _ReadingStepState();
}

class _ReadingStepState extends ConsumerState<ReadingStep> {
  final _scroll = ScrollController();
  final Map<String, List<GlobalKey>> _paraKeys = {};
  final Map<String, LocateTarget> _locate = {};

  List<GlobalKey> _keysFor(Reading r) =>
      _paraKeys.putIfAbsent(r.id, () => List.generate(r.paragraphs.length, (_) => GlobalKey()));

  void _jumpTo(Reading r, Question q) {
    final target = locateFor(r, q);
    setState(() => _locate[r.id] = target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keysFor(r)[target.para].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeOut, alignment: 0.15);
      }
    });
  }

  Future<void> _confirmRedo(AppStore store, Reading r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重做本篇阅读题？'),
        content: const Text('只清除这篇的 5 道阅读题作答；听读题、标注和笔记都保留。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('重做')),
        ],
      ),
    );
    if (ok == true) {
      store.redo(widget.data.day, 'reading', r.id);
      setState(() => _locate.remove(r.id));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final rid = ref.watch(readingTabProvider);
    final reading = d.reading(rid);
    final c = context.c;

    return StoreBuilder(builder: (context, store) {
      final attempt = store.peekAttempt(d.day, 'reading', rid);
      final answers = attempt?.answers ?? const <String, String>{};
      final submitted = attempt?.submitted ?? false;
      final listening = store.peekAttempt(d.day, 'listening', rid);
      final annotations = store.annotationsFor(d.day, rid);
      final keys = _keysFor(reading);
      final locate = _locate[rid];

      return ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
        children: [
          TodayHeader(data: d),
          Row(
            children: [
              for (final r in d.readings) ...[
                Flexible(
                  child: _ReadingChip(
                    label: r.label,
                    selected: r.id == rid,
                    status: _status(store, d.day, r),
                    onTap: () => ref.read(readingTabProvider.notifier).select(r.id),
                  ),
                ),
                const SizedBox(width: AppSpace.s2),
              ],
              QuietButton(
                label: '朗读',
                icon: Icons.headphones_outlined,
                onPressed: () => context.push('/listen/${d.day}/$rid'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('READING PASSAGE'),
                const SizedBox(height: AppSpace.s2),
                Text(reading.title, style: TextStyle(fontFamily: readingFont, fontSize: 22, height: 1.3, color: c.ink)),
                const SizedBox(height: AppSpace.s1),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${countWords(reading.paragraphs.join(' '))} 词 · 5 题 + ${reading.listeningQuestions.length} 道听读',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => showAnnotationSheet(context, store, () => store.annotationsFor(d.day, rid), '${reading.label} · 标注合集'),
                      icon: Icon(Icons.edit_note, size: 18, color: c.blue),
                      label: Text('标注 ${annotations.length}', style: TextStyle(color: c.blue, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s3),
                for (var i = 0; i < reading.paragraphs.length; i++)
                  PassageBlock(
                    key: keys[i],
                    paraIndex: i,
                    text: reading.paragraphs[i],
                    locateRange: locate != null && locate.para == i ? (start: locate.start, end: locate.end) : null,
                    annotations: annotations.where((a) => a.paraIndex == i).toList(),
                    onAnnotate: (s, e) => annotateSelection(
                      context,
                      store,
                      day: d.day,
                      target: rid,
                      paraIndex: i,
                      paragraph: reading.paragraphs[i],
                      start: s,
                      end: e,
                    ),
                  ),
                Text('长按选词可「标注」用法；标注只保存在本机。', style: TextStyle(fontSize: 12, color: c.muted)),
                if (reading.translation.isNotEmpty)
                  FoldSection(
                    title: '全文翻译（中文）',
                    icon: Icons.translate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < reading.translation.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.s3),
                            child: Text('${i + 1}  ${reading.translation[i]}', style: TextStyle(fontSize: 15, height: 1.7, color: c.inkSoft)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          if (submitted) ...[
            ScoreBanner(
              label: '${reading.label} 阅读',
              score: attempt!.score ?? 0,
              total: attempt.total ?? reading.questions.length,
              onRedo: () => _confirmRedo(store, reading),
            ),
            const SizedBox(height: AppSpace.s3),
          ],
          for (var i = 0; i < reading.questions.length; i++) ...[
            QuestionCard(
              index: i,
              total: reading.questions.length,
              question: reading.questions[i],
              selected: answers[reading.questions[i].id],
              submitted: submitted,
              onSelect: (l) => store.answer(d.day, 'reading', rid, reading.questions[i].id, l),
              onLocate: () => _jumpTo(reading, reading.questions[i]),
            ),
            const SizedBox(height: AppSpace.s3),
          ],
          if (!submitted)
            PrimaryButton(
              label: allAnswered(reading.questions, answers)
                  ? '提交本篇'
                  : '提交本篇（已答 ${answers.length}/${reading.questions.length}）',
              icon: Icons.fact_check_outlined,
              onPressed: allAnswered(reading.questions, answers)
                  ? () {
                      final g = grade(reading.questions, answers);
                      store.submit(d.day, 'reading', rid, score: g.correct, total: g.total);
                      ref.read(countdownHubProvider).get('${d.day}|reading|$rid', const Duration(minutes: 9)).pause();
                      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) showToast(context, '${reading.label}：${g.correct}/${g.total}，逐题看定位和解析');
                      });
                    }
                  : null,
            ),
          const SizedBox(height: AppSpace.s3),
          PaperCard(
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Row(
              children: [
                Icon(Icons.headphones_outlined, color: c.blue),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Text(
                    listening?.submitted ?? false
                        ? '本篇听读：${listening!.score}/${listening.total}'
                        : '本篇还有 ${reading.listeningQuestions.length} 道听读题，在朗读模式里完成',
                    style: TextStyle(fontSize: 14, color: c.inkSoft),
                  ),
                ),
                QuietButton(label: '去听读', onPressed: () => context.push('/listen/${d.day}/$rid')),
              ],
            ),
          ),
        ],
      );
    });
  }

  String _status(AppStore store, int day, Reading r) {
    final a = store.peekAttempt(day, 'reading', r.id);
    if (a?.submitted ?? false) return '${a!.score}/${a.total}';
    final n = a?.answers.length ?? 0;
    return n == 0 ? '未做' : '$n/${r.questions.length}';
  }
}

class _ReadingChip extends StatelessWidget {
  const _ReadingChip({required this.label, required this.selected, required this.status, required this.onTap});

  final String label;
  final bool selected;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: selected ? c.blueSoft : c.paper,
      shape: StadiumBorder(side: BorderSide(color: selected ? c.blue : c.line, width: selected ? 1.5 : 1)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? c.blue : c.ink)),
              TextSpan(text: ' $status', style: TextStyle(fontSize: 12, color: c.muted)),
            ]),
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
