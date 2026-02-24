import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/messaging_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessagingPreferencesServiceImpl', () {
    test('load defaults to all enabled when keys are missing', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MessagingPreferencesServiceImpl(
        preferencesFactory: SharedPreferences.getInstance,
      );

      final snapshot = await service.load();

      expect(snapshot.typingIndicatorsEnabled, isTrue);
      expect(snapshot.deliveryReceiptsEnabled, isTrue);
      expect(snapshot.readReceiptsEnabled, isTrue);
    });

    test('setTypingIndicatorsEnabled persists value', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MessagingPreferencesServiceImpl(
        preferencesFactory: SharedPreferences.getInstance,
      );

      final snapshot = await service.setTypingIndicatorsEnabled(false);

      expect(snapshot.typingIndicatorsEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings.typing_indicators_enabled'), isFalse);
    });

    test('setDeliveryReceiptsEnabled persists value', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MessagingPreferencesServiceImpl(
        preferencesFactory: SharedPreferences.getInstance,
      );

      final snapshot = await service.setDeliveryReceiptsEnabled(false);

      expect(snapshot.deliveryReceiptsEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings.delivery_receipts_enabled'), isFalse);
    });

    test('setReadReceiptsEnabled persists value', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MessagingPreferencesServiceImpl(
        preferencesFactory: SharedPreferences.getInstance,
      );

      final snapshot = await service.setReadReceiptsEnabled(false);

      expect(snapshot.readReceiptsEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings.read_receipts_enabled'), isFalse);
    });
  });
}
