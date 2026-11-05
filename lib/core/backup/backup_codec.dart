import '../spec/validate_day.dart';
import '../storage/records.dart';

const backupSchema = 'cet6.backup.v1';

/// 设置里不允许进入备份的键（凭据类）。API 配置本就只在 Keystore，这里是第二道防线。
bool isSensitiveSettingKey(String key) {
  final k = key.toLowerCase();
  return k.contains('key') || k.contains('token') || k.contains('authorization') || k.contains('secret') || k.contains('baseurl');
}

class BackupData {
  BackupData({
    required this.attempts,
    required this.drafts,
    required this.annotations,
    required this.notes,
    required this.reviews,
    required this.settings,
    this.generatedDays = const [],
    this.rejectedGeneratedDays = 0,
    this.exportedAt,
    this.appVersion = '1.0.0',
  });

  final List<AttemptRec> attempts;
  final List<DraftRec> drafts;
  final List<AnnotationRec> annotations;
  final List<NoteRec> notes;
  final List<ReviewRec> reviews;
  final Map<String, String> settings;
  final List<GeneratedDayRec> generatedDays;

  /// 导入时未通过质检而被丢弃的生成题包数。
  final int rejectedGeneratedDays;
  final DateTime? exportedAt;
  final String appVersion;

  Map<String, dynamic> toJson() => {
        'schema': backupSchema,
        'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
        'appVersion': appVersion,
        'state': {
          'attempts': attempts.map((e) => e.toJson()).toList(),
          'drafts': drafts.map((e) => e.toJson()).toList(),
          'annotations': annotations.map((e) => e.toJson()).toList(),
          'notes': notes.map((e) => e.toJson()).toList(),
          'reviews': reviews.map((e) => e.toJson()).toList(),
          'settings': {
            for (final e in settings.entries)
              if (!isSensitiveSettingKey(e.key)) e.key: e.value,
          },
        },
        'generatedDays': generatedDays.map((e) => e.toJson()).toList(),
      };

  static BackupData fromJson(Map<String, dynamic> j) {
    if (j['schema'] != backupSchema) {
      throw const FormatException('不是本 App 的备份文件（schema 不匹配）');
    }
    final s = (j['state'] as Map?)?.cast<String, dynamic>() ?? const {};
    List<Map<String, dynamic>> list(String k) =>
        ((s[k] as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    final generated = <GeneratedDayRec>[];
    var rejected = 0;
    for (final raw in (j['generatedDays'] as List?) ?? const []) {
      try {
        final rec = GeneratedDayRec.fromJson((raw as Map).cast());
        if (rec.payload['day'] == rec.day && validateDay(rec.payload).ok) {
          generated.add(rec);
        } else {
          rejected++;
        }
      } catch (_) {
        rejected++;
      }
    }
    return BackupData(
      generatedDays: generated,
      rejectedGeneratedDays: rejected,
      attempts: list('attempts').map(AttemptRec.fromJson).toList(),
      drafts: list('drafts').map(DraftRec.fromJson).toList(),
      annotations: list('annotations').map(AnnotationRec.fromJson).toList(),
      notes: list('notes').map(NoteRec.fromJson).toList(),
      reviews: list('reviews').map(ReviewRec.fromJson).toList(),
      settings: {
        for (final e in ((s['settings'] as Map?) ?? const {}).entries)
          if (!isSensitiveSettingKey(e.key.toString())) e.key.toString(): e.value.toString(),
      },
      exportedAt: DateTime.tryParse(j['exportedAt'] as String? ?? ''),
      appVersion: j['appVersion'] as String? ?? '',
    );
  }

  Set<int> get days => {
        ...attempts.map((e) => e.day),
        ...drafts.map((e) => e.day),
        ...annotations.map((e) => e.day),
        ...notes.map((e) => e.day),
        ...reviews.map((e) => e.day),
        ...generatedDays.map((e) => e.day),
      };

  String summary() {
    final d = days.toList()..sort();
    final gen = generatedDays.isEmpty ? '' : '、AI 题包 ${generatedDays.length} 天';
    final bad = rejectedGeneratedDays == 0 ? '' : '\n另有 $rejectedGeneratedDays 天题包未通过质检，将被跳过。';
    return '涉及 ${d.isEmpty ? 0 : d.length} 个训练日${d.isEmpty ? '' : '（Day ${d.join('、')}）'}：'
        '作答 ${attempts.length} 条、草稿 ${drafts.length} 条、标注 ${annotations.length} 条、'
        '笔记 ${notes.length} 篇、复盘 ${reviews.length} 条$gen。$bad';
  }
}
