import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/spec/day_model.dart';
import '../../domain/grading.dart';
import 'locate_quote.dart';
import 'paper_card.dart';

enum OptionState { idle, selected, correct, wrong, disabled }

/// 答题卡式横向选项条：选中 = 左侧色块 + 描边加深。
class OptionRow extends StatelessWidget {
  const OptionRow({super.key, required this.letter, required this.text, required this.state, this.onTap});

  final String letter;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (Color border, Color strip, Color bg, Color fg) = switch (state) {
      // v1.3：选中 = 左色块 + 描边加深 + 卷面底，不再用 blueSoft 大面积填充。
      OptionState.selected => (c.blue, c.blue, c.paper, c.ink),
      OptionState.correct => (c.green, c.green, c.greenSoft, c.ink),
      OptionState.wrong => (c.red, c.red, c.redSoft, c.ink),
      OptionState.disabled => (c.lineSoft, Colors.transparent, c.paper, c.muted),
      OptionState.idle => (c.line, Colors.transparent, c.paper, c.ink),
    };
    final mark = switch (state) {
      OptionState.correct => Icon(Icons.check_circle, size: 18, color: c.green),
      OptionState.wrong => Icon(Icons.cancel, size: 18, color: c.red),
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s2),
      child: Semantics(
        button: onTap != null,
        selected: state == OptionState.selected,
        label: '选项 $letter',
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: border, width: state == OptionState.idle ? 1 : 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: strip),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s3 - 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(letter, style: TextStyle(fontWeight: FontWeight.w700, color: strip == Colors.transparent ? c.muted : strip)),
                            ),
                            Expanded(child: Text(text, style: TextStyle(fontSize: 15, height: 1.45, color: fg))),
                            if (mark != null) ...[const SizedBox(width: 6), mark],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// v1.3：定位引文收敛到 ui/components/locate_quote.dart（唯一 Component Set）。
// inline / card 两个变体共用 markerSoft 实色，深色下 ink / markerSoft = 9.02:1。

class ExplainBlock extends StatelessWidget {
  const ExplainBlock({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s3),
      decoration: BoxDecoration(color: c.blueSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('解析', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.blue)),
          const SizedBox(height: 4),
          Text(text, style: TextStyle(fontSize: 14, height: 1.6, color: c.inkSoft)),
        ],
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.index,
    required this.total,
    required this.question,
    required this.selected,
    required this.submitted,
    required this.onSelect,
    this.onLocate,
  });

  final int index;
  final int total;
  final Question question;
  final String? selected;
  final bool submitted;
  final ValueChanged<String> onSelect;
  final VoidCallback? onLocate;

  OptionState _state(String letter) {
    if (!submitted) return selected == letter ? OptionState.selected : OptionState.idle;
    if (letter == question.answer) return OptionState.correct;
    if (letter == selected) return OptionState.wrong;
    return OptionState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final right = selected == question.answer;
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.s4, AppSpace.s4, AppSpace.s4, AppSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${index + 1} / $total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.blue)),
              Text(' · ${question.type}', style: TextStyle(fontSize: 12, color: c.muted)),
              const Spacer(),
              if (submitted)
                Text(
                  right ? '正确' : (selected == null ? '未作答 · 答案 ${question.answer}' : '错误 · 答案 ${question.answer}'),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: right ? c.green : c.red),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s2),
          Text(question.stem, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, height: 1.45)),
          const SizedBox(height: AppSpace.s3),
          for (var i = 0; i < question.options.length && i < optionLetters.length; i++)
            OptionRow(
              letter: optionLetters[i],
              text: question.options[i],
              state: _state(optionLetters[i]),
              onTap: submitted ? null : () => onSelect(optionLetters[i]),
            ),
          if (submitted) ...[
            const SizedBox(height: AppSpace.s1),
            LocateQuote(para: question.locatePara, quote: question.locateQuote, onLocate: onLocate),
            const SizedBox(height: AppSpace.s2),
            ExplainBlock(text: question.explain),
            const SizedBox(height: AppSpace.s2),
          ],
        ],
      ),
    );
  }
}

/// 得分条：「3 / 5 · 下次目标 4/5」。
class ScoreBanner extends StatelessWidget {
  const ScoreBanner({super.key, required this.label, required this.score, required this.total, this.onRedo});

  final String label;
  final int score;
  final int total;
  final VoidCallback? onRedo;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final good = score >= (total * 0.8).ceil();
    final target = score >= total ? total : score + 1;
    return PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4, vertical: AppSpace.s3),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: c.muted)),
          const SizedBox(width: AppSpace.s2),
          Text(
            '$score / $total',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: good ? c.green : c.red,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpace.s2),
          Expanded(
            child: Text(score >= total ? '全对，保持' : '下次目标 $target/$total', style: TextStyle(fontSize: 13, color: c.muted)),
          ),
          if (onRedo != null)
            TextButton(onPressed: onRedo, child: Text('重做', style: TextStyle(color: c.blue, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
