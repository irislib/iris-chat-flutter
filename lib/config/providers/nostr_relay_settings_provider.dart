import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/nostr_relay_settings_service.dart';
import '../../core/services/nostr_service.dart';

class NostrRelaySettingsState {
  NostrRelaySettingsState({
    this.isLoading = true,
    List<String>? relays,
    this.error,
  }) : relays = List<String>.unmodifiable(
         relays ?? List<String>.from(NostrService.defaultRelays),
       );

  final bool isLoading;
  final List<String> relays;
  final String? error;

  NostrRelaySettingsState copyWith({
    bool? isLoading,
    List<String>? relays,
    String? error,
    bool clearError = false,
  }) {
    return NostrRelaySettingsState(
      isLoading: isLoading ?? this.isLoading,
      relays: relays ?? this.relays,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NostrRelaySettingsNotifier
    extends StateNotifier<NostrRelaySettingsState> {
  NostrRelaySettingsNotifier(this._service, {bool autoLoad = true})
    : super(NostrRelaySettingsState()) {
    if (autoLoad) {
      Future<void>.microtask(load);
    }
  }

  final NostrRelaySettingsService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.load();
      state = state.copyWith(
        isLoading: false,
        relays: snapshot.relayUrls,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addRelay(String relayUrl) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.addRelay(relayUrl);
      state = state.copyWith(
        isLoading: false,
        relays: snapshot.relayUrls,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateRelay(String oldRelayUrl, String newRelayUrl) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.updateRelay(oldRelayUrl, newRelayUrl);
      state = state.copyWith(
        isLoading: false,
        relays: snapshot.relayUrls,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeRelay(String relayUrl) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.removeRelay(relayUrl);
      state = state.copyWith(
        isLoading: false,
        relays: snapshot.relayUrls,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final nostrRelaySettingsServiceProvider = Provider<NostrRelaySettingsService>((
  ref,
) {
  return NostrRelaySettingsServiceImpl();
});

final nostrRelaySettingsProvider =
    StateNotifierProvider<NostrRelaySettingsNotifier, NostrRelaySettingsState>((
      ref,
    ) {
      final service = ref.watch(nostrRelaySettingsServiceProvider);
      return NostrRelaySettingsNotifier(service);
    });
