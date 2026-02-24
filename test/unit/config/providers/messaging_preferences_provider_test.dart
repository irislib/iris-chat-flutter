import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/config/providers/messaging_preferences_provider.dart';
import 'package:iris_chat/core/services/messaging_preferences_service.dart';

class FakeMessagingPreferencesService implements MessagingPreferencesService {
  FakeMessagingPreferencesService({
    this.typingEnabled = true,
    this.deliveryEnabled = true,
    this.readEnabled = true,
    this.throwOnLoad = false,
    this.throwOnTyping = false,
  });

  bool typingEnabled;
  bool deliveryEnabled;
  bool readEnabled;
  final bool throwOnLoad;
  final bool throwOnTyping;

  @override
  Future<MessagingPreferencesSnapshot> load() async {
    if (throwOnLoad) throw Exception('load failed');
    return MessagingPreferencesSnapshot(
      typingIndicatorsEnabled: typingEnabled,
      deliveryReceiptsEnabled: deliveryEnabled,
      readReceiptsEnabled: readEnabled,
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
}

void main() {
  group('MessagingPreferencesNotifier', () {
    test('load sets values from service', () async {
      final notifier = MessagingPreferencesNotifier(
        FakeMessagingPreferencesService(
          typingEnabled: false,
          deliveryEnabled: true,
          readEnabled: false,
        ),
        autoLoad: false,
      );

      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.typingIndicatorsEnabled, isFalse);
      expect(notifier.state.deliveryReceiptsEnabled, isTrue);
      expect(notifier.state.readReceiptsEnabled, isFalse);
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
