import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/spec/day_model.dart';
import '../../domain/grading.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';
import '../../ui/components/passage_block.dart';
import '../../ui/components/question_card.dart';
import '../today/reading_step.dart';
import 'reading_aloud.dart';

/// 朗读模式：上方「文章 / 听力题」切换，底部常驻朗读控制条；切换时不中断朗读。
class ReadingModePage extends ConsumerWidget {
  const ReadingModePage({super.key, required this.day, required this.readingId});

  final int day;
  final String readingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dayDataProvider(day));
    return data.when(
      data: (d) => _ReadingModeBody(data: d, reading: d.reading(readingId)),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('加载失败：$e'))),
    );
  }
}

class _ReadingModeBody extends ConsumerStatefulWidget {
  const _ReadingModeBody({required this.data, required this.reading});

  final DayData data;
  final Reading reading;

  @override
  ConsumerState<_ReadingModeBody> createState() => _ReadingModeBodyState();
}

class _ReadingModeBodyState extends ConsumerState<_ReadingModeBody> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late final ReadingAloud _aloud = ref.read(readingAloudProvider);
  late final List<GlobalKey> _paraKeys = List.generate(widget.reading.paragraphs.length, (_) => GlobalKey());
  LocateTarget? _locate;

  String get _sourceKey => '${widget.data.day}|${widget.reading.id}';

  @override
  void initState() {
    super.initState();
    _aloud.attach(_sourceKey, widget.reading.paragraphs);
    _aloud.addListener(_followSpeaking);
  }

  int _lastFollowed = -1;

  void _followSpeaking() {
    if (!_aloud.playing || _aloud.currentPara == _lastFollowed || _tabs.index != 0) return;
    _lastFollowed = _aloud.currentPara;
    _scrollToPara(_aloud.currentPara);
  }

  void _scrollToPara(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _paraKeys[i].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeOut, alignment: 0.2);
      }
    });
  }

  void _locateQuestion(Question q) {
    final t = locateFor(widget.reading, q);
    setState(() => _locate = t);
    _tabs.animateTo(0);
    Future.delayed(const Duration(milliseconds: 260), () => _scrollToPara(t.para));
  }

  @override
  void dispose() {
    _aloud.removeListener(_followSpeaking);
    _aloud.stop();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final r = widget.reading;
    final c = context.c;
    return StoreBuilder(builder: (context, store) {
      final attempt = store.peekAttempt(d.day, 'listening', r.id);
      final answers = attempt?.answers ?? const <String, String>{};
      final submitted = attempt?.submitted ?? false;
      final qs = r.listeningQuestions;

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), tooltip: '退出朗读模式', onPressed: () => Navigator.pop(context)),
          title: Text('朗读模式 · ${r.label}'),
          bottom: TabBar(
            controller: _tabs,
            labelColor: c.blue,
            unselectedLabelColor: c.muted,
            indicatorColor: c.blue,
            tabs: [
              const Tab(text: '文章'),
              Tab(text: submitted ? '听力题 ${attempt!.score}/${attempt.total}' : '听力题 ${answers.length}/${qs.length}'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            ListenableBuilder(
              listenable: _aloud,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s4, AppSpace.page, AppSpace.s8),
                children: [
                  if (_aloud.error != null) ...[
                    PaperCard(
                      color: c.redSoft,
                      padding: const EdgeInsets.all(AppSpace.s3),
                      child: Text(_aloud.error!, style: TextStyle(color: c.red, fontSize: 14)),
                    ),
                    const SizedBox(height: AppSpace.s3),
                  ],
                  PaperCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('LISTEN & READ'),
                        const SizedBox(height: AppSpace.s2),
                        Text(r.title, style: TextStyle(fontFamily: readingFont, fontSize: 22, height: 1.3, color: c.ink)),
                        const SizedBox(height: AppSpace.s1),
                        Text('点段落从这里开始朗读', style: TextStyle(fontSize: 12, color: c.muted)),
                        const SizedBox(height: AppSpace.s3),
                        for (var i = 0; i < r.paragraphs.length; i++)
                          PassageBlock(
                            key: _paraKeys[i],
                            paraIndex: i,
                            text: r.paragraphs[i],
                            speaking: _aloud.isSource(_sourceKey) && _aloud.currentPara == i && _aloud.playing,
                            locateRange: _locate != null && _locate!.para == i ? (start: _locate!.start, end: _locate!.end) : null,
                            onTap: () => _aloud.play(from: i),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s4, AppSpace.page, AppSpace.s8),
              children: [
                Text('先听 / 读文章，再做 4 道听读题；与阅读题分开保存和判分。', style: TextStyle(fontSize: 13, color: c.muted)),
                const SizedBox(height: AppSpace.s3),
                if (submitted) ...[
                  ScoreBanner(
                    label: '听读',
                    score: attempt!.score ?? 0,
                    total: attempt.total ?? qs.length,
                    onRedo: () {
                      store.redo(d.day, 'listening', r.id);
                      setState(() => _locate = null);
                    },
                  ),
                  const SizedBox(height: AppSpace.s3),
                ],
                for (var i = 0; i < qs.length; i++) ...[
                  QuestionCard(
                    index: i,
                    total: qs.length,
                    question: qs[i],
                    selected: answers[qs[i].id],
                    submitted: submitted,
                    onSelect: (l) => store.answer(d.day, 'listening', r.id, qs[i].id, l),
                    onLocate: () => _locateQuestion(qs[i]),
                  ),
                  const SizedBox(height: AppSpace.s3),
                ],
                if (!submitted)
                  PrimaryButton(
                    label: allAnswered(qs, answers) ? '提交听力题' : '提交听力题（已答 ${answers.length}/${qs.length}）',
                    icon: Icons.fact_check_outlined,
                    onPressed: allAnswered(qs, answers)
                        ? () {
                            final g = grade(qs, answers);
                            store.submit(d.day, 'listening', r.id, score: g.correct, total: g.total);
                            showToast(context, '听读 ${g.correct}/${g.total}');
                          }
                        : null,
                  ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: ListeningBar(aloud: _aloud, sourceKey: _sourceKey),
      );
    });
  }
}

/// 常驻底部的朗读控制条：播放 / 暂停、当前段、倍速。
class ListeningBar extends StatelessWidget {
  const ListeningBar({super.key, required this.aloud, required this.sourceKey});

  final ReadingAloud aloud;
  final String sourceKey;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListenableBuilder(
      listenable: aloud,
      builder: (context, _) {
        final active = aloud.isSource(sourceKey);
        final playing = active && aloud.playing;
        return Container(
          decoration: BoxDecoration(color: c.paper, border: Border(top: BorderSide(color: c.line))),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s2),
              child: Row(
                children: [
                  IconButton.filled(
                    iconSize: 28,
                    style: IconButton.styleFrom(backgroundColor: c.blue, minimumSize: const Size(52, 52)),
                    tooltip: playing ? '暂停' : '播放',
                    onPressed: aloud.toggle,
                    icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(playing ? '正在朗读' : '已暂停', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
                        Text(
                          '第 ${aloud.currentPara + 1} / ${aloud.paragraphCount} 段',
                          style: TextStyle(fontSize: 12, color: c.muted, fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ),
                  for (final r in ReadingAloud.rates)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ChoiceChip(
                        label: Text('${r}x'),
                        selected: aloud.rate == r,
                        showCheckmark: false,
                        selectedColor: c.blueSoft,
                        side: BorderSide(color: aloud.rate == r ? c.blue : c.line),
                        labelStyle: TextStyle(fontSize: 12, color: aloud.rate == r ? c.blue : c.inkSoft, fontWeight: FontWeight.w600),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => aloud.setRate(r),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}