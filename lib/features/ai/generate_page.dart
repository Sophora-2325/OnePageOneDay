import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/generation/generation_engine.dart';
import '../../core/network/llm_client.dart';
import '../../core/storage/records.dart';
import '../../domain/grading.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/day_header.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';

enum _Phase { idle, running, failed }

class GeneratePage extends ConsumerStatefulWidget {
  const GeneratePage({super.key});

  @override
  ConsumerState<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends ConsumerState<GeneratePage> {
  final _focus = TextEditingController();
  final _events = <GenEvent>[];
  _Phase _phase = _Phase.idle;
  CancelToken? _cancel;
  GenerationFailed? _failure;
  int? _dayNo;

  @override
  void dispose() {
    _cancel?.cancel();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final model = ref.read(chatModelProvider);
    if (model == null) {
      context.push('/api');
      return;
    }
    final repo = ref.read(dayRepositoryProvider);
    final store = ref.read(storeProvider);
    final index = await repo.index();
    final presets = await repo.presetIndex();
    final dayNo = await repo.nextDayNumber();
    final last = DateTime.parse(index.last.date).add(const Duration(days: 1));
    final now = DateTime.now();
    final date = (last.isAfter(now) ? last : now).toIso8601String().substring(0, 10);

    final titles = <String>[];
    final topics = <String>[];
    for (final e in index.reversed.take(14)) {
      final d = await repo.load(e.day);
      titles.addAll(d.readings.map((r) => r.title));
      topics.add(d.writing.topic);
    }

    setState(() {
      _phase = _Phase.running;
      _events.clear();
      _failure = null;
      _dayNo = dayNo;
      _cancel = CancelToken();
    });
    try {
      final day = await GenerationEngine(model).generate(
        GenerationRequest(
          dayNo: dayNo,
          date: date,
          example: await repo.presetRaw(presets.last.day),
          avoidTitles: titles,
          avoidWritingTopics: topics,
          focus: _focus.text,
        ),
        onEvent: (e) {
          if (mounted) setState(() => _events.add(e));
        },
        cancel: _cancel,
      );
      await store.addGeneratedDay(GeneratedDayRec(day: dayNo, payload: day, model: ref.read(apiConfigProvider).model));
      if (!mounted) return;
      refreshDays(ref);
      _openDay(dayNo);
      showToast(context, '${dayLabel(dayNo)} 已生成，并通过全部质检');
    } on GenerationFailed catch (e) {
      if (!mounted) return;
      switch (e.cause?.kind) {
        case LlmErrorKind.cancelled:
          setState(() => _phase = _Phase.idle);
        case LlmErrorKind.offline:
          await _fallback('离线也能练：已为你打开预置题');
        default:
          setState(() {
            _phase = _Phase.failed;
            _failure = e;
          });
      }
    }
  }

  void _openDay(int day) {
    ref.read(currentDayProvider.notifier).select(day);
    ref.read(todayStepProvider.notifier).select(0);
    ref.read(readingTabProvider.notifier).select('r1');
    context.go('/today');
  }

  Future<void> _fallback(String message) async {
    final presets = await ref.read(dayRepositoryProvider).presetIndex();
    final day = pickDefaultDay(presets, DateTime.now());
    if (!mounted) return;
    _openDay(day);
    showToast(context, message.replaceAll('{day}', dayLabel(day)));
  }

  Future<bool> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('停止生成？'),
        content: const Text('已完成的部分不会保存，也不会产生任何题目。已消耗的 token 无法退回。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('继续生成')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('停止')),
        ],
      ),
    );
    if (ok == true) _cancel?.cancel();
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.running,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmCancel() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_dayNo == null ? '生成新的一天' : '生成 ${dayLabel(_dayNo!)}')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
          children: switch (_phase) {
            _Phase.idle => _idle(context),
            _Phase.running => _running(context),
            _Phase.failed => _failed(context),
          },
        ),
      ),
    );
  }

  List<Widget> _idle(BuildContext context) {
    final c = context.c;
    final cfg = ref.watch(apiConfigProvider);
    return [
      Text(
        '用你配置的模型（${cfg.model.isEmpty ? '未配置' : cfg.model}）生成一整天：2 篇阅读（各 5 题 + 4 道听读题、逐段译文）、1 段翻译、1 篇写作。',
        style: TextStyle(fontSize: 14, height: 1.6, color: c.inkSoft),
      ),
      const SizedBox(height: AppSpace.s4),
      TextField(
        controller: _focus,
        maxLength: 40,
        decoration: const InputDecoration(labelText: '想练的方向（可不填）', hintText: '例如：环境类话题、人工智能与就业'),
      ),
      const SizedBox(height: AppSpace.s2),
      PaperCard(
        color: c.lineSoft,
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Line(Icons.fact_check_outlined, '每段都过自动质检：定位引文必须逐字在原文中、题量与词数达标；不合格会定向修复，最多 3 次。'),
          _Line(Icons.block, '仍不合格就不交付，坏题不会进入题库。'),
          _Line(Icons.schedule, '通常需要 2–6 分钟，期间请保持在本页。'),
          _Line(Icons.privacy_tip_outlined, '请求只含命题规范与示例，不上传你的作答、笔记和标注。'),
        ]),
      ),
      const SizedBox(height: AppSpace.s6),
      PrimaryButton(label: '开始生成', icon: Icons.auto_awesome, onPressed: _start),
    ];
  }

  List<Widget> _running(BuildContext context) {
    final c = context.c;
    final repairs = _events.where((e) => e.kind == GenEventKind.repair).toList();
    return [
      PaperCard(
        child: Column(children: [
          for (final s in GenStage.values) _StageRow(stage: s, events: _events.where((e) => e.stage == s).toList()),
        ]),
      ),
      if (repairs.isNotEmpty) ...[
        const SizedBox(height: AppSpace.s4),
        const SectionTitle('质检记录'),
        for (final r in repairs)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.build_circle_outlined, size: 16, color: c.blue),
              const SizedBox(width: AppSpace.s2),
              Expanded(child: Text(r.message, style: TextStyle(fontSize: 13, height: 1.5, color: c.inkSoft))),
            ]),
          ),
      ],
      const SizedBox(height: AppSpace.s6),
      Center(child: QuietButton(label: '停止生成', icon: Icons.stop_circle_outlined, color: c.red, onPressed: _confirmCancel)),
    ];
  }

  List<Widget> _failed(BuildContext context) {
    final c = context.c;
    final f = _failure!;
    final kind = f.cause?.kind;
    final (title, detail) = switch (kind) {
      LlmErrorKind.unauthorized => ('密钥未通过验证', '去看 30 秒教程，检查密钥是否复制完整、是否欠费。已填写的配置会保留。'),
      LlmErrorKind.rateLimited => ('模型侧繁忙，稍后再试', '已自动退避重试过。可以先练预置题，过一会儿再来生成。'),
      LlmErrorKind.timeout => ('生成超时，未产生任何题目', '没有任何半成品被保存，可以直接重试。'),
      LlmErrorKind.invalidConfig || LlmErrorKind.http => ('请求没有成功', f.message),
      LlmErrorKind.badResponse => ('模型返回的不是正常回复', f.message),
      _ => ('未通过质检，没有交付', '${f.message}。坏题不会进入题库；可以重试，或换一个能力更强的模型。'),
    };
    final repairs = _events.where((e) => e.kind == GenEventKind.repair).toList();
    return [
      PaperCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.error_outline, color: c.red),
            const SizedBox(width: AppSpace.s2),
            Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink))),
          ]),
          const SizedBox(height: AppSpace.s2),
          Text(detail, style: TextStyle(fontSize: 14, height: 1.6, color: c.inkSoft)),
          if (repairs.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s3),
            for (final r in repairs) Text('· ${r.message}', style: TextStyle(fontSize: 12, height: 1.6, color: c.muted)),
          ],
        ]),
      ),
      const SizedBox(height: AppSpace.s4),
      if (kind == LlmErrorKind.unauthorized || kind == LlmErrorKind.invalidConfig || kind == LlmErrorKind.http) ...[
        PrimaryButton(label: '看教程', icon: Icons.school_outlined, onPressed: () => context.push('/tutorial')),
        const SizedBox(height: AppSpace.s3),
      ],
      OutlineAction(label: '重试', icon: Icons.refresh, onPressed: _start),
      const SizedBox(height: AppSpace.s3),
      OutlineAction(
        label: '先练预置题',
        icon: Icons.menu_book_outlined,
        onPressed: () => _fallback(kind == null ? '未通过质检，已使用 {day} 预置题' : '已为你打开 {day} 预置题'),
      ),
    ];
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.events});

  final GenStage stage;
  final List<GenEvent> events;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final last = events.isEmpty ? null : events.last;
    final repairs = events.where((e) => e.kind == GenEventKind.repair).length;
    final Widget lead = switch (last?.kind) {
      null => Icon(Icons.radio_button_unchecked, size: 20, color: c.line),
      GenEventKind.passed => Icon(Icons.check_circle, size: 20, color: c.green),
      _ => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
    };
    final status = switch (last?.kind) {
      null => '等待',
      GenEventKind.passed => repairs == 0 ? '通过' : '修复 $repairs 次后通过',
      GenEventKind.repair => '定向修复中（第 $repairs 次）',
      GenEventKind.start => '生成中',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      child: Row(children: [
        lead,
        const SizedBox(width: AppSpace.s3),
        Expanded(child: Text(stage.label, style: TextStyle(fontSize: 15, color: last == null ? c.muted : c.ink))),
        Text(status, style: TextStyle(fontSize: 12, color: last?.kind == GenEventKind.passed ? c.green : c.muted)),
      ]),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: c.muted),
        const SizedBox(width: AppSpace.s2),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.6, color: c.inkSoft))),
      ]),
    );
  }
}
