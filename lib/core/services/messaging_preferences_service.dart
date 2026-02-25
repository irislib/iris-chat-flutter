import 'package:shared_preferences/shared_preferences.dart';

/// Persisted outbound messaging behavior preferences.
class MessagingPreferencesSnapshot {
  const MessagingPreferencesSnapshot({
    required this.typingIndicatorsEnabled,
    required this.deliveryReceiptsEnabled,
    required this.readReceiptsEnabled,
    required this.desktopNotificationsEnabled,
  });

  final bool typingIndicatorsEnabled;
  final bool deliveryReceiptsEnabled;
  final bool readReceiptsEnabled;
  final bool desktopNotificationsEnabled;
}

abstract class MessagingPreferencesService {
  Future<MessagingPreferencesSnapshot> load();
  Future<MessagingPreferencesSnapshot> setTypingIndicatorsEnabled(bool value);
  Future<MessagingPreferencesSnapshot> setDeliveryReceiptsEnabled(bool value);
  Future<MessagingPreferencesSnapshot> setReadReceiptsEnabled(bool value);
  Future<MessagingPreferencesSnapshot> setDesktopNotificationsEnabled(bool value);
}

class MessagingPreferencesServiceImpl implements MessagingPreferencesService {
  MessagingPreferencesServiceImpl({
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance;

  static const _typingKey = 'settings.typing_indicators_enabled';
  static const _deliveryReceiptsKey = 'settings.delivery_receipts_enabled';
  static const _readReceiptsKey = 'settings.read_receipts_enabled';
  static const _desktopNotificationsKey =
      'settings.desktop_notifications_enabled';

  final Future<SharedPreferences> Function() _preferencesFactory;

  @override
  Future<MessagingPreferencesSnapshot> load() async {
    final prefs = await _preferencesFactory();
    return _snapshotFromPrefs(prefs);
  }

  @override
  Future<MessagingPreferencesSnapshot> setTypingIndicatorsEnabled(
    bool value,
  ) async {
    final prefs = await _preferencesFactory();
    await prefs.setBool(_typingKey, value);
    return _snapshotFromPrefs(prefs);
  }

  @override
  Future<MessagingPreferencesSnapshot> setDeliveryReceiptsEnabled(
    bool value,
  ) async {
    final prefs = await _preferencesFactory();
    await prefs.setBool(_deliveryReceiptsKey, value);
    return _snapshotFromPrefs(prefs);
  }

  @override
  Future<MessagingPreferencesSnapshot> setReadReceiptsEnabled(
    bool value,
  ) async {
    final prefs = await _preferencesFactory();
    await prefs.setBool(_readReceiptsKey, value);
    return _snapshotFromPrefs(prefs);
  }

  @override
  Future<MessagingPreferencesSnapshot> setDesktopNotificationsEnabled(
    bool value,
  ) async {
    final prefs = await _preferencesFactory();
    await prefs.setBool(_desktopNotificationsKey, value);
    return _snapshotFromPrefs(prefs);
  }

  MessagingPreferencesSnapshot _snapshotFromPrefs(SharedPreferences prefs) {
    return MessagingPreferencesSnapshot(
      typingIndicatorsEnabled: prefs.getBool(_typingKey) ?? true,
      deliveryReceiptsEnabled: prefs.getBool(_deliveryReceiptsKey) ?? true,
      readReceiptsEnabled: prefs.getBool(_readReceiptsKey) ?? true,
      desktopNotificationsEnabled:
          prefs.getBool(_desktopNotificationsKey) ?? true,
    );
  }
}
