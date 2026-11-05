import 'dart:convert';
import 'dart:typed_data';

import 'package:cet6_app/core/update/update_checker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final String body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['application/octet-stream'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> manifest(String version, {String? apk}) => {
      'version': version,
      'notes': ['新增艾笔'],
      'apk': apk ?? 'https://github.com/Sophora-2325/OnePageOneDay/releases/download/v$version/yiye-english-$version.apk',
    };

void main() {
  test('版本号比较', () {
    expect(compareVersions('1.2.0', '1.1.9'), greaterThan(0));
    expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
    expect(compareVersions('1.2.0', '1.2.0+5'), 0);
    expect(compareVersions('1.1.0', '1.2.0'), lessThan(0));
  });

  test('有新版：只发一次无参数 GET 到固定地址', () async {
    final adapter = _Adapter(200, jsonEncode(manifest('9.0.0')));
    final r = await checkForUpdate(currentVersion: '1.2.0', dio: Dio()..httpClientAdapter = adapter);
    expect(r, isA<UpdateAvailable>());
    expect((r as UpdateAvailable).info.downloadUrl, endsWith('yiye-english-9.0.0.apk'));
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.uri.toString(), versionManifestUrl);
    expect(adapter.requests.single.uri.query, isEmpty);
  });

  test('已是最新', () async {
    final r = await checkForUpdate(
      currentVersion: '1.2.0',
      dio: Dio()..httpClientAdapter = _Adapter(200, jsonEncode(manifest('1.2.0'))),
    );
    expect(r, isA<UpToDate>());
  });

  test('下载链接被篡改到别的域名时，退回官方 Release 页', () {
    final info = UpdateInfo.fromJson(manifest('2.0.0', apk: 'https://evil.example.com/a.apk'));
    expect(info.downloadUrl, releasesPageUrl);
  });

  test('404 与坏 JSON 都只提示、不崩溃', () async {
    final r404 = await checkForUpdate(currentVersion: '1.2.0', dio: Dio()..httpClientAdapter = _Adapter(404, 'Not Found'));
    expect((r404 as UpdateFailed).message, '还没有发布任何版本');
    final bad = await checkForUpdate(currentVersion: '1.2.0', dio: Dio()..httpClientAdapter = _Adapter(200, '<html>'));
    expect(bad, isA<UpdateFailed>());
  });
}
