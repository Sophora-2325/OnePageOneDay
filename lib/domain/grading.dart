import '../core/spec/day_model.dart';

const optionLetters = ['A', 'B', 'C', 'D'];

class GradeResult {
  const GradeResult({required this.correct, required this.total, required this.wrongIds});

  final int correct;
  final int total;
  final List<String> wrongIds;
}

/// [answers]：题目 id → 所选字母。
GradeResult grade(List<Question> questions, Map<String, String> answers) {
  var correct = 0;
  final wrong = <String>[];
  for (final q in questions) {
    if (answers[q.id] == q.answer) {
      correct++;
    } else {
      wrong.add(q.id);
    }
  }
  return GradeResult(correct: correct, total: questions.length, wrongIds: wrong);
}

bool allAnswered(List<Question> questions, Map<String, String> answers) =>
    questions.every((q) => answers[q.id] != null);

/// 英文词数：按空白切分，过滤空字符串；连字符词算一个词（内容规范 §7）。
int countWords(String text) => text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

/// 中文汉字数：只统计 [\u4e00-\u9fff]。
int countHanzi(String text) => RegExp(r'[\u4e00-\u9fff]').allMatches(text).length;

/// 选默认训练日：日期等于今天的那天；否则不晚于今天的最后一天；否则第一天。
int pickDefaultDay(List<DayIndexEntry> days, DateTime today) {
  if (days.isEmpty) return 1;
  final key = _dateKey(today);
  for (final d in days) {
    if (d.date == key) return d.day;
  }
  final past = days.where((d) => d.date.compareTo(key) <= 0).toList();
  return past.isNotEmpty ? past.last.day : days.first.day;
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
