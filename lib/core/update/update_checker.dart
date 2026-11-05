// 版本检查：唯一允许的开发者侧网络资产。只在用户手动点击时，对一个静态 version.json 发一次 GET，
// 不带任何参数与设备信息；有新版只提示，下载交给系统浏览器。

import 'dart:convert';

import 'package:dio/dio.dart';

const versionManifestUrl = 'https://github.com/Sophora-2325/OnePageOneDay/releases/latest/download/version.json';
const releasesPageUrl = 'https://github.com/Sophora-2325/OnePageOneDay/releases/latest';

class UpdateInfo {
  const UpdateInfo({required this.version, required this.notes, required this.downloadUrl, this.published = ''});

  final String version;
  final List<String> notes;
  final String downloadUrl;
  final String published;

  /// 下载链接只接受 https，且必须指向本项目的 GitHub Release，防止清单被篡改后诱导下载。
  static UpdateInfo fromJson(Map<String, dynamic> j) {
    final version = j['version'];
    if (version is! String || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
      throw const FormatException('版本号格式不对');
    }
    final apk = j['apk'] is String ? j['apk'] as String : '';
    final uri = Uri.tryParse(apk);
    final trusted = uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'github.com' &&
        uri.path.startsWith('/Sophora-2325/OnePageOneDay/releases/');
    return UpdateInfo(
      version: version,
      notes: (j['notes'] as List? ?? const []).map((e) => '$e').toList(),
      downloadUrl: trusted ? apk : releasesPageUrl,
      published: j['published'] is String ? j['published'] as String : '',
    );
  }
}

/// a > b 返回正数，相等为 0。
int compareVersions(String a, String b) {
  List<int> parts(String v) => v.split('+').first.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0, y = i < pb.length ? pb[i] : 0;
    if (x != y) return x - y;
  }
  return 0;
}

sealed class UpdateResult {
  const UpdateResult();
}

class UpToDate extends UpdateResult {
  const UpToDate(this.latest);
  final String latest;
}

class UpdateAvailable extends UpdateResult {
  const UpdateAvailable(this.info);
  final UpdateInfo info;
}

class UpdateFailed extends UpdateResult {
  const UpdateFailed(this.message);
  final String message;
}

Future<UpdateResult> checkForUpdate({required String currentVersion, Dio? dio}) async {
  try {
    final res = await (dio ?? Dio()).get<Object?>(
      versionManifestUrl,
      options: Options(
        responseType: ResponseType.plain,
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        followRedirects: true,
        validateStatus: (_) => true,
      ),
    );
    if (res.statusCode == 404) return const UpdateFailed('还没有发布任何版本');
    if ((res.statusCode ?? 0) >= 300) return UpdateFailed('检查失败（HTTP ${res.statusCode}）');
    final body = res.data;
    final json = body is String ? jsonDecode(body) : body;
    final info = UpdateInfo.fromJson((json as Map).cast<String, dynamic>());
    return compareVersions(info.version, currentVersion) > 0 ? UpdateAvailable(info) : UpToDate(info.version);
  } on DioException catch (e) {
    return UpdateFailed(e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown
        ? '无法连接 GitHub，请检查网络后再试'
        : '检查超时，请稍后再试');
  } catch (_) {
    return const UpdateFailed('版本信息格式不对，已忽略');
  }
}
