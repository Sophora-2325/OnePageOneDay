import '../../domain/training_scope.dart';
import '../spec/validate_day.dart';
import '../storage/records.dart';

/// v2：每条记录显式带 goal，各档进度各自独立；仍接受 1.0 的 v1 备份（整体归入六级）。
/// 已下线的历史档位记录仍按原档解码，不并入六级。
const backupSchema = 'cet6.backup.v2';
const legacyBackupSchema = 'cet6.backup.v1';

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

  /// 导出时用平台真实版本覆盖默认的 '1.0.0'；存储层不依赖 Flutter 插件。
  BackupData withAppVersion(String version) => BackupData(
        attempts: attempts,
        drafts: drafts,
        annotations: annotations,
        notes: notes,
        reviews: reviews,
        settings: settings,
        generatedDays: generatedDays,
        rejectedGeneratedDays: rejectedGeneratedDays,
        exportedAt: exportedAt,
        appVersion: version,
      );

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
    final schema = j['schema'];
    if (schema != backupSchema && schema != legacyBackupSchema) {
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
        // 题包自带的档位必须与记录一致；用该档自己的规范重新过质检。
        final payloadGoal = rec.payload['goal']?.toString();
        final consistent = payloadGoal == null || payloadGoal == rec.goal.name;
        if (consistent && rec.payload['day'] == rec.day && validateDay(rec.payload, goal: rec.goal).ok) {
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

  /// 兼容旧调用：所有档训练日号的并集（不区分档）。
  Set<int> get days => {
        for (final set in daysByGoal.values) ...set,
      };

  /// 按档分组的训练日，供 summary 与导入预览使用。
  Map<GoalId, Set<int>> get daysByGoal {
    final out = <GoalId, Set<int>>{};
    void add(GoalId g, int day) => out.putIfAbsent(g, () => <int>{}).add(day);
    for (final e in attempts) {
      add(e.goal, e.day);
    }
    for (final e in drafts) {
      add(e.goal, e.day);
    }
    for (final e in annotations) {
      add(e.goal, e.day);
    }
    for (final e in notes) {
      add(e.goal, e.day);
    }
    for (final e in reviews) {
      add(e.goal, e.day);
    }
    for (final e in generatedDays) {
      add(e.goal, e.day);
    }
    return out;
  }

  String summary() {
    final parts = <String>[];
    for (final g in kGoals) {
      final d = daysByGoal[g.id];
      if (d == null || d.isEmpty) continue;
      final list = d.toList()..sort();
      parts.add('${g.name} ${d.length} 天（Day ${list.join('、')}）');
    }
    final scope = parts.isEmpty ? '暂无训练日' : '涉及 ${parts.join('；')}';
    final gen = generatedDays.isEmpty ? '' : '、AI 题包 ${generatedDays.length} 天';
    final bad = rejectedGeneratedDays == 0 ? '' : '\n另有 $rejectedGeneratedDays 天题包未通过质检，将被跳过。';
    return '$scope：'
        '作答 ${attempts.length} 条、草稿 ${drafts.length} 条、标注 ${annotations.length} 条、'
        '笔记 ${notes.length} 篇、复盘 ${reviews.length} 条$gen。$bad';
  }
}
