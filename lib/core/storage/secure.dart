import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 用户自备的模型 API 配置。只存在于 Keystore 与单次请求头，
/// 不进 SQLite、不进日志、不进备份；[toString] 刻意不输出密钥。
class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.model, required this.apiKey});

  static const empty = ApiConfig(baseUrl: '', model: '', apiKey: '');

  final String baseUrl;
  final String model;
  final String apiKey;

  bool get isComplete => baseUrl.trim().isNotEmpty && model.trim().isNotEmpty && apiKey.trim().isNotEmpty;

  String get maskedKey {
    final k = apiKey.trim();
    if (k.isEmpty) return '未填写';
    if (k.length <= 8) return '****';
    return '${k.substring(0, 3)}****${k.substring(k.length - 4)}';
  }

  @override
  String toString() => 'ApiConfig(baseUrl: $baseUrl, model: $model, apiKey: $maskedKey)';
}

abstract class ApiConfigStore {
  Future<ApiConfig> read();
  Future<void> write(ApiConfig config);
  Future<void> clear();
}

class SecureApiConfigStore implements ApiConfigStore {
  SecureApiConfigStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kBase = 'llm.base_url';
  static const _kModel = 'llm.model';
  static const _kKey = 'llm.api_key';

  @override
  Future<ApiConfig> read() async {
    try {
      return ApiConfig(
        baseUrl: await _storage.read(key: _kBase) ?? '',
        model: await _storage.read(key: _kModel) ?? '',
        apiKey: await _storage.read(key: _kKey) ?? '',
      );
    } catch (_) {
      // Keystore 损坏（如系统还原后密钥失效）时视为未配置，不阻断离线训练。
      return ApiConfig.empty;
    }
  }

  @override
  Future<void> write(ApiConfig config) async {
    await _storage.write(key: _kBase, value: config.baseUrl.trim());
    await _storage.write(key: _kModel, value: config.model.trim());
    await _storage.write(key: _kKey, value: config.apiKey.trim());
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kBase);
    await _storage.delete(key: _kModel);
    await _storage.delete(key: _kKey);
  }
}

class MemoryApiConfigStore implements ApiConfigStore {
  MemoryApiConfigStore([this._config = ApiConfig.empty]);

  ApiConfig _config;

  @override
  Future<ApiConfig> read() async => _config;

  @override
  Future<void> write(ApiConfig config) async => _config = config;

  @override
  Future<void> clear() async => _config = ApiConfig.empty;
}
