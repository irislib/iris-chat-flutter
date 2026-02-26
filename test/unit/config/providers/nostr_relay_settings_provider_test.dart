import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/config/providers/nostr_relay_settings_provider.dart';
import 'package:iris_chat/core/services/nostr_relay_settings_service.dart';

class FakeNostrRelaySettingsService implements NostrRelaySettingsService {
  FakeNostrRelaySettingsService({
    required List<String> initialRelays,
    this.throwOnLoad = false,
    this.throwOnAdd = false,
    this.throwOnUpdate = false,
    this.throwOnRemove = false,
  }) : _relayUrls = List<String>.from(initialRelays);

  final bool throwOnLoad;
  final bool throwOnAdd;
  final bool throwOnUpdate;
  final bool throwOnRemove;
  final List<String> _relayUrls;

  @override
  Future<NostrRelaySettingsSnapshot> load() async {
    if (throwOnLoad) throw Exception('load failed');
    return NostrRelaySettingsSnapshot(relayUrls: List<String>.from(_relayUrls));
  }

  @override
  Future<NostrRelaySettingsSnapshot> addRelay(String relayUrl) async {
    if (throwOnAdd) throw Exception('add failed');
    _relayUrls.add(relayUrl);
    return load();
  }

  @override
  Future<NostrRelaySettingsSnapshot> updateRelay(
    String oldRelayUrl,
    String newRelayUrl,
  ) async {
    if (throwOnUpdate) throw Exception('update failed');
    final index = _relayUrls.indexOf(oldRelayUrl);
    if (index < 0) throw StateError('Relay not found');
    _relayUrls[index] = newRelayUrl;
    return load();
  }

  @override
  Future<NostrRelaySettingsSnapshot> removeRelay(String relayUrl) async {
    if (throwOnRemove) throw Exception('remove failed');
    _relayUrls.remove(relayUrl);
    return load();
  }
}

void main() {
  group('NostrRelaySettingsNotifier', () {
    test('load sets relays from service', () async {
      final notifier = NostrRelaySettingsNotifier(
        FakeNostrRelaySettingsService(
          initialRelays: const ['wss://relay.a', 'wss://relay.b'],
        ),
        autoLoad: false,
      );

      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.relays, const ['wss://relay.a', 'wss://relay.b']);
      expect(notifier.state.error, isNull);
    });

    test('addRelay updates state from service', () async {
      final notifier = NostrRelaySettingsNotifier(
        FakeNostrRelaySettingsService(initialRelays: const ['wss://relay.a']),
        autoLoad: false,
      );
      await notifier.load();

      await notifier.addRelay('wss://relay.b');

      expect(notifier.state.relays, const ['wss://relay.a', 'wss://relay.b']);
      expect(notifier.state.error, isNull);
    });

    test('updateRelay updates state from service', () async {
      final notifier = NostrRelaySettingsNotifier(
        FakeNostrRelaySettingsService(initialRelays: const ['wss://relay.a']),
        autoLoad: false,
      );
      await notifier.load();

      await notifier.updateRelay('wss://relay.a', 'wss://relay.updated');

      expect(notifier.state.relays, const ['wss://relay.updated']);
      expect(notifier.state.error, isNull);
    });

    test('removeRelay updates state from service', () async {
      final notifier = NostrRelaySettingsNotifier(
        FakeNostrRelaySettingsService(
          initialRelays: const ['wss://relay.a', 'wss://relay.b'],
        ),
        autoLoad: false,
      );
      await notifier.load();

      await notifier.removeRelay('wss://relay.a');

      expect(notifier.state.relays, const ['wss://relay.b']);
      expect(notifier.state.error, isNull);
    });

    test('set error when service throws during load', () async {
      final notifier = NostrRelaySettingsNotifier(
        FakeNostrRelaySettingsService(
          initialRelays: const ['wss://relay.a'],
          throwOnLoad: true,
        ),
        autoLoad: false,
      );

      await notifier.load();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
    });
  });
}
