import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_focus_service.dart';

/// Local-notification transport abstraction for unit testing.
abstract class LocalNotificationBackend {
  bool get isSupported;
  Future<void> ensureInitialized();
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

/// Real local-notification backend powered by flutter_local_notifications.
class FlutterLocalNotificationBackend implements LocalNotificationBackend {
  FlutterLocalNotificationBackend({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  @override
  Future<void> ensureInitialized() async {
    if (_initialized || !isSupported) return;

    const settings = InitializationSettings(
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
        requestSoundPermission: true,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!isSupported) return;
    await ensureInitialized();
    const details = NotificationDetails(
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      linux: LinuxNotificationDetails(),
    );
    await _plugin.show(id, title, body, details);
  }
}

/// Surface for desktop local notifications.
abstract class DesktopNotificationService {
  bool get isSupported;

  Future<void> showIncomingMessage({
    required bool enabled,
    required String conversationTitle,
    required String body,
  });

  Future<void> showIncomingReaction({
    required bool enabled,
    required String conversationTitle,
    required String emoji,
    required String targetPreview,
  });
}

/// No-op desktop notification service.
class NoopDesktopNotificationService implements DesktopNotificationService {
  const NoopDesktopNotificationService();

  @override
  bool get isSupported => false;

  @override
  Future<void> showIncomingMessage({
    required bool enabled,
    required String conversationTitle,
    required String body,
  }) async {}

  @override
  Future<void> showIncomingReaction({
    required bool enabled,
    required String conversationTitle,
    required String emoji,
    required String targetPreview,
  }) async {}
}

/// Production desktop notification service with focus-aware suppression.
class DesktopNotificationServiceImpl implements DesktopNotificationService {
  DesktopNotificationServiceImpl({
    required AppFocusState appFocusState,
    LocalNotificationBackend? backend,
  }) : _appFocusState = appFocusState,
       _backend = backend ?? FlutterLocalNotificationBackend();

  final AppFocusState _appFocusState;
  final LocalNotificationBackend _backend;
  int _nextNotificationId = 1;

  @override
  bool get isSupported => _backend.isSupported;

  @override
  Future<void> showIncomingMessage({
    required bool enabled,
    required String conversationTitle,
    required String body,
  }) async {
    await _notifyIfAllowed(
      enabled: enabled,
      title: _truncate(conversationTitle.trim(), 96),
      body: _truncate(body.trim(), 220),
    );
  }

  @override
  Future<void> showIncomingReaction({
    required bool enabled,
    required String conversationTitle,
    required String emoji,
    required String targetPreview,
  }) async {
    final cleanEmoji = emoji.trim();
    final cleanPreview = targetPreview.trim();
    final body = cleanPreview.isEmpty
        ? 'New reaction $cleanEmoji'
        : 'Reaction $cleanEmoji to "$cleanPreview"';
    await _notifyIfAllowed(
      enabled: enabled,
      title: _truncate(conversationTitle.trim(), 96),
      body: _truncate(body, 220),
    );
  }

  Future<void> _notifyIfAllowed({
    required bool enabled,
    required String title,
    required String body,
  }) async {
    if (!enabled || !_backend.isSupported) return;
    if (_appFocusState.isAppFocused) return;

    await _backend.ensureInitialized();
    await _backend.show(
      id: _nextNotificationId++,
      title: title.isEmpty ? 'iris chat' : title,
      body: body.isEmpty ? 'New chat activity' : body,
    );
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }
}
