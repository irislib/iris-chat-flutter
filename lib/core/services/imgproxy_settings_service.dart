import 'package:shared_preferences/shared_preferences.dart';

import 'imgproxy_service.dart';

class ImgproxySettingsSnapshot {
  const ImgproxySettingsSnapshot({
    required this.enabled,
    required this.url,
    required this.keyHex,
    required this.saltHex,
  });

  final bool enabled;
  final String url;
  final String keyHex;
  final String saltHex;
}

abstract class ImgproxySettingsService {
  Future<ImgproxySettingsSnapshot> load();
  Future<ImgproxySettingsSnapshot> setEnabled(bool value);
  Future<ImgproxySettingsSnapshot> setUrl(String value);
  Future<ImgproxySettingsSnapshot> setKeyHex(String value);
  Future<ImgproxySettingsSnapshot> setSaltHex(String value);
  Future<ImgproxySettingsSnapshot> resetDefaults();
}

class ImgproxySettingsServiceImpl implements ImgproxySettingsService {
  ImgproxySettingsServiceImpl({
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance;

  static const _enabledKey = 'settings.imgproxy.enabled';
  static const _urlKey = 'settings.imgproxy.url';
  static const _keyHexKey = 'settings.imgproxy.key_hex';
  static const _saltHexKey = 'settings.imgproxy.salt_hex';

  final Future<SharedPreferences> Function() _preferencesFactory;

  @override
  Future<ImgproxySettingsSnapshot> load() async {
    final prefs = await _preferencesFactory();
    return _snapshotFromPrefs(prefs);
  }

  @override
  Future<ImgproxySettingsSnapshot> setEnabled(bool value) async {
    final prefs = await _preferencesFactory();
    await prefs.setBool(_enabledKey, value);
    return _snapshotFromPrefs(prefs);
  }

  @override
  Future<ImgproxySettingsSnapshot> setUrl(String value) async {
    final prefs = await _preferencesFactory();
    final normalized = value.trim();
    if (normalized.isEmpty) {
      await prefs.remove(_urlKey);
    } else {
      await prefs.setString(_urlKey, normalized);
    }
    return _snapshotFromPrefs(prefs);
  }

  @override
  Future<ImgproxySettingsSnapshot> setKeyHex(String value) async {
    final prefs = await _preferencesFactory();
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      await prefs.remove(_keyHexKey);
    } else {
      await prefs.setString(_keyHexKey, normalized);
    }
    return _snapshotFromPrefs(prefs);
  }

  @override
  Future<ImgproxySettingsSnapshot> setSaltHex(String value) async {
    final prefs = await _preferencesFactory();
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      await prefs.remove(_saltHexKey);
    } else {
      await prefs.setString(_saltHexKey, normalized);
    }
    return _snapshotFromPrefs(prefs);
  }

  @override
  Future<ImgproxySettingsSnapshot> resetDefaults() async {
    final prefs = await _preferencesFactory();
    await prefs.remove(_urlKey);
    await prefs.remove(_keyHexKey);
    await prefs.remove(_saltHexKey);
    await prefs.setBool(_enabledKey, true);
    return _snapshotFromPrefs(prefs);
  }

  ImgproxySettingsSnapshot _snapshotFromPrefs(SharedPreferences prefs) {
    return ImgproxySettingsSnapshot(
      enabled: prefs.getBool(_enabledKey) ?? true,
      url: prefs.getString(_urlKey) ?? ImgproxyConfig.defaultUrl,
      keyHex: prefs.getString(_keyHexKey) ?? ImgproxyConfig.defaultKeyHex,
      saltHex: prefs.getString(_saltHexKey) ?? ImgproxyConfig.defaultSaltHex,
    );
  }
}
