import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/config/providers/messaging_preferences_provider.dart';
import 'package:iris_chat/core/services/messaging_preferences_service.dart';

class FakeMessagingPreferencesService implements MessagingPreferencesService {
  FakeMessagingPreferencesService({
    this.typingEnabled = true,
    this.deliveryEnabled = true,
    this.readEnabled = true,
    this.desktopNotificationsEnabled = true,
    this.mobilePushNotificationsEnabled = true,
    this.throwOnLoad = false,
    this.throwOnTyping = false,
  });

  bool typingEnabled;
  bool deliveryEnabled;
  bool readEnabled;
  bool desktopNotificationsEnabled;
  bool mobilePushNotificationsEnabled;
  final bool throwOnLoad;
  final bool throwOnTyping;

  @override
  Future<MessagingPreferencesSnapshot> load() async {
    if (throwOnLoad) throw Exception('load failed');
    return MessagingPreferencesSnapshot(
      typingIndicatorsEnabled: typingEnabled,
      deliveryReceiptsEnabled: deliveryEnabled,
      readReceiptsEnabled: readEnabled,
      desktopNotificationsEnabled: desktopNotificationsEnabled,
      mobilePushNotificationsEnabled: mobilePushNotificationsEnabled,
    );
  }

  @override
  Future<MessagingPreferencesSnapshot> setTypingIndicatorsEnabled(
    bool value,
  ) async {
    if (throwOnTyping) throw Exception('set typing failed');
    typingEnabled = value;
    return load();
  }

  @override
  Future<MessagingPreferencesSnapshot> setDeliveryReceiptsEnabled(
    bool value,
  ) async {
    deliveryEnabled = value;
    return load();
  }

  @override
  Future<MessagingPreferencesSnapshot> setReadReceiptsEnabled(
    bool value,
  ) async {
    readEnabled = value;
    return load();
  }

  @override
  Future<MessagingPreferencesSnapshot> setDesktopNotificationsEnabled(
    bool value,
  ) async {
    desktopNotificationsEnabled = value;
    return load();
  }

  @override
  Future<MessagingPreferencesSnapshot> setMobilePushNotificationsEnabled(
    bool value,
  ) async {
    mobilePushNotificationsEnabled = value;
    return load();
  }
}

void main() {
  group('MessagingPreferencesNotifier', () {
    test('load sets values from service', () async {
      final notifier = MessagingPreferencesNotifier(
        FakeMessagingPreferencesService(
          typingEnabled: false,
          deliveryEnabled: true,
          readEnabled: false,
          desktopNotificationsEnabled: false,
          mobilePushNotificationsEnabled: false,
        ),
        autoLoad: false,
      );

      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.typingIndicatorsEnabled, isFalse);
      expect(notifier.state.deliveryReceiptsEnabled, isTrue);
      expect(notifier.state.readReceiptsEnabled, isFalse);
      expect(notifier.state.desktopNotificationsEnabled, isFalse);
      expect(notifier.state.mobilePushNotificationsEnabled, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('setTypingIndicatorsEnabled updates state', () async {
      final notifier = MessagingPreferencesNotifier(
        FakeMessagingPreferencesService(),
        autoLoad: false,
      );
      await notifier.load();

      await notifier.setTypingIndicatorsEnabled(false);

      expect(notifier.state.typingIndicatorsEnabled, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('setDesktopNotificationsEnabled updates state', () async {
      final notifier = MessagingPreferencesNotifier(
        FakeMessagingPreferencesService(),
        autoLoad: false,
      );
      await notifier.load();

      await notifier.setDesktopNotificationsEnabled(false);

      expect(notifier.state.desktopNotificationsEnabled, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('setMobilePushNotificationsEnabled updates state', () async {
      final notifier = MessagingPreferencesNotifier(
        FakeMessagingPreferencesService(),
        autoLoad: false,
      );
      await notifier.load();

      await notifier.setMobilePushNotificationsEnabled(false);

      expect(notifier.state.mobilePushNotificationsEnabled, isFalse);
      expect(notifier.state.error, isNull);
    });

    test(
      'setTypingIndicatorsEnabled stores error when service throws',
      () async {
        final notifier = MessagingPreferencesNotifier(
          FakeMessagingPreferencesService(throwOnTyping: true),
          autoLoad: false,
        );
        await notifier.load();

        await notifier.setTypingIndicatorsEnabled(false);

        expect(notifier.state.typingIndicatorsEnabled, isTrue);
        expect(notifier.state.error, isNotNull);
      },
    );

    test('load stores error when service throws', () async {
      final notifier = MessagingPreferencesNotifier(
        FakeMessagingPreferencesService(throwOnLoad: true),
        autoLoad: false,
      );

      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
    });
  });
}
