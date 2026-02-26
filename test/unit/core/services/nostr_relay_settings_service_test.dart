import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/nostr_relay_settings_service.dart';
import 'package:iris_chat/core/services/nostr_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NostrRelaySettingsServiceImpl', () {
    test(
      'load defaults to built-in relays when settings are missing',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = NostrRelaySettingsServiceImpl(
          preferencesFactory: SharedPreferences.getInstance,
        );

        final snapshot = await service.load();

        expect(snapshot.relayUrls, NostrService.defaultRelays);
      },
    );

    test('addRelay persists normalized relay url', () async {
      SharedPreferences.setMockInitialValues({
        'settings.nostr_relay_urls': <String>['wss://relay.damus.io'],
      });
      final service = NostrRelaySettingsServiceImpl(
        preferencesFactory: SharedPreferences.getInstance,
      );

      final snapshot = await service.addRelay(' wss://relay.example.com/ ');

      expect(snapshot.relayUrls, [
        'wss://relay.damus.io',
        'wss://relay.example.com',
      ]);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('settings.nostr_relay_urls'), [
        'wss://relay.damus.io',
        'wss://relay.example.com',
      ]);
    });

    test('addRelay throws when adding a duplicate relay', () async {
      SharedPreferences.setMockInitialValues({
        'settings.nostr_relay_urls': <String>['wss://relay.example.com'],
      });
      final service = NostrRelaySettingsServiceImpl(
        preferencesFactory: SharedPreferences.getInstance,
      );

      expect(
        () => service.addRelay('wss://relay.example.com'),
        throwsStateError,
      );
    });

    test('updateRelay replaces existing relay', () async {
      SharedPreferences.setMockInitialValues({
        'settings.nostr_relay_urls': <String>[
          'wss://relay.damus.io',
          'wss://relay.snort.social',
        ],
      });
      final service = NostrRelaySettingsServiceImpl(
        preferencesFactory: SharedPreferences.getInstance,
      );

      final snapshot = await service.updateRelay(
        'wss://relay.snort.social',
        'wss://relay.primal.net',
      );

      expect(snapshot.relayUrls, [
        'wss://relay.damus.io',
        'wss://relay.primal.net',
      ]);
    });

    test('removeRelay throws when removing the last relay', () async {
      SharedPreferences.setMockInitialValues({
        'settings.nostr_relay_urls': <String>['wss://relay.only.one'],
      });
      final service = NostrRelaySettingsServiceImpl(
        preferencesFactory: SharedPreferences.getInstance,
      );

      expect(
        () => service.removeRelay('wss://relay.only.one'),
        throwsStateError,
      );
    });

    test('normalizeNostrRelayUrl requires ws or wss url', () {
      expect(
        () => normalizeNostrRelayUrl('https://relay.example.com'),
        throwsFormatException,
      );
      expect(() => normalizeNostrRelayUrl('not-a-url'), throwsFormatException);
      expect(
        normalizeNostrRelayUrl(' WSS://relay.example.com/ '),
        'wss://relay.example.com',
      );
    });
  });
}
