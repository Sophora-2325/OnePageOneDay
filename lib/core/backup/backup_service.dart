import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../storage/app_store.dart';
import 'backup_codec.dart';

class BackupService {
  BackupService(this.store);

  final AppStore store;

  /// 写出备份文件并打开系统分享面板（可存到文件、网盘或发给自己）。
  Future<String> export() async {
    final data = store.snapshot();
    final json = const JsonEncoder.withIndent('  ').convert(data.toJson());
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 16).replaceAll(':', '').replaceAll('T', '-');
    final file = File(p.join(dir.path, 'cet6-backup-$stamp.json'));
    await file.writeAsString(json);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      subject: 'CET-6 每日训练备份',
      text: '六级每日训练本地备份（不含任何 API 密钥）',
    ));
    store.setSetting('lastBackupAt', DateTime.now().toIso8601String());
    return file.path;
  }

  /// 选择备份文件并解析；返回 null 表示用户取消。
  Future<BackupData?> pick() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (files.isEmpty) return null;
    final raw = utf8.decode(await files.first.readAsBytes());
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('文件内容不是 JSON 对象');
    return BackupData.fromJson(decoded.cast<String, dynamic>());
  }
}
