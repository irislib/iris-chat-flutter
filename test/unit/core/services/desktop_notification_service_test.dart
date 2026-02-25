import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/app_focus_service.dart';
import 'package:iris_chat/core/services/desktop_notification_service.dart';

class FakeAppFocusState implements AppFocusState {
  FakeAppFocusState({required this.isAppFocused});

  @override
  bool isAppFocused;
}

class FakeNotificationBackend implements LocalNotificationBackend {
  FakeNotificationBackend({required this.isSupported});

  @override
  final bool isSupported;

  int showCalls = 0;
  int initializeCalls = 0;
  final List<(String title, String body)> shown = [];

  @override
  Future<void> ensureInitialized() async {
    initializeCalls += 1;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    showCalls += 1;
    shown.add((title, body));
  }
}

void main() {
  group('DesktopNotificationServiceImpl', () {
    test('does not notify when disabled', () async {
      final backend = FakeNotificationBackend(isSupported: true);
      final service = DesktopNotificationServiceImpl(
        appFocusState: FakeAppFocusState(isAppFocused: false),
        backend: backend,
      );

      await service.showIncomingMessage(
        enabled: false,
        conversationTitle: 'Alice',
        body: 'hello',
      );

      expect(backend.showCalls, 0);
    });

    test('does not notify while app is focused', () async {
      final backend = FakeNotificationBackend(isSupported: true);
      final service = DesktopNotificationServiceImpl(
        appFocusState: FakeAppFocusState(isAppFocused: true),
        backend: backend,
      );

      await service.showIncomingMessage(
        enabled: true,
        conversationTitle: 'Alice',
        body: 'hello',
      );

      expect(backend.showCalls, 0);
    });

    test(
      'shows incoming message notification when enabled and unfocused',
      () async {
        final backend = FakeNotificationBackend(isSupported: true);
        final service = DesktopNotificationServiceImpl(
          appFocusState: FakeAppFocusState(isAppFocused: false),
          backend: backend,
        );

        await service.showIncomingMessage(
          enabled: true,
          conversationTitle: 'Alice',
          body: 'hello',
        );

        expect(backend.initializeCalls, 1);
        expect(backend.showCalls, 1);
        expect(backend.shown.single.$1, 'Alice');
        expect(backend.shown.single.$2, 'hello');
      },
    );

    test('formats incoming reaction notification body', () async {
      final backend = FakeNotificationBackend(isSupported: true);
      final service = DesktopNotificationServiceImpl(
        appFocusState: FakeAppFocusState(isAppFocused: false),
        backend: backend,
      );

      await service.showIncomingReaction(
        enabled: true,
        conversationTitle: 'Alice',
        emoji: '🔥',
        targetPreview: 'Nice image',
      );

      expect(backend.showCalls, 1);
      expect(backend.shown.single.$1, 'Alice');
      expect(backend.shown.single.$2, contains('🔥'));
      expect(backend.shown.single.$2, contains('Nice image'));
    });
  });
}
