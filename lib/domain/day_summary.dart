import '../core/storage/app_store.dart';

/// 某训练日的本地成绩汇总（只用已提交的作答）。
class DaySummary {
  const DaySummary({
    required this.day,
    required this.readingScore,
    required this.readingTotal,
    required this.readingSubmitted,
    required this.listeningScore,
    required this.listeningTotal,
    required this.listeningSubmitted,
    required this.done,
  });

  final int day;
  final int readingScore;
  final int readingTotal;
  final int readingSubmitted;
  final int listeningScore;
  final int listeningTotal;
  final int listeningSubmitted;
  final bool done;

  bool get started => readingSubmitted > 0 || listeningSubmitted > 0 || done;

  static DaySummary of(AppStore store, int day) {
    var rs = 0, rt = 0, rn = 0, ls = 0, lt = 0, ln = 0;
    for (final a in store.attempts.where((a) => a.day == day && a.submitted)) {
      if (a.kind == 'reading') {
        rs += a.score ?? 0;
        rt += a.total ?? 0;
        rn++;
      } else if (a.kind == 'listening') {
        ls += a.score ?? 0;
        lt += a.total ?? 0;
        ln++;
      }
    }
    return DaySummary(
      day: day,
      readingScore: rs,
      readingTotal: rt,
      readingSubmitted: rn,
      listeningScore: ls,
      listeningTotal: lt,
      listeningSubmitted: ln,
      done: store.peekReview(day)?.done ?? false,
    );
  }
}

/// 截至 [days] 中最后一个已完成日往前的连续完成天数。
int completionStreak(List<int> days, Set<int> done) {
  final sorted = [...days]..sort();
  var streak = 0;
  var counting = false;
  for (final d in sorted.reversed) {
    if (done.contains(d)) {
      counting = true;
      streak++;
    } else if (counting) {
      break;
    }
  }
  return streak;
}
