import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/messaging_preferences_service.dart';

class MessagingPreferencesState {
  const MessagingPreferencesState({
    this.isLoading = true,
    this.typingIndicatorsEnabled = true,
    this.deliveryReceiptsEnabled = true,
    this.readReceiptsEnabled = true,
    this.error,
  });

  final bool isLoading;
  final bool typingIndicatorsEnabled;
  final bool deliveryReceiptsEnabled;
  final bool readReceiptsEnabled;
  final String? error;

  MessagingPreferencesState copyWith({
    bool? isLoading,
    bool? typingIndicatorsEnabled,
    bool? deliveryReceiptsEnabled,
    bool? readReceiptsEnabled,
    String? error,
    bool clearError = false,
  }) {
    return MessagingPreferencesState(
      isLoading: isLoading ?? this.isLoading,
      typingIndicatorsEnabled:
          typingIndicatorsEnabled ?? this.typingIndicatorsEnabled,
      deliveryReceiptsEnabled:
          deliveryReceiptsEnabled ?? this.deliveryReceiptsEnabled,
      readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MessagingPreferencesNotifier
    extends StateNotifier<MessagingPreferencesState> {
  MessagingPreferencesNotifier(this._service, {bool autoLoad = true})
    : super(const MessagingPreferencesState()) {
    if (autoLoad) {
      Future<void>.microtask(load);
    }
  }

  final MessagingPreferencesService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.load();
      state = state.copyWith(
        isLoading: false,
        typingIndicatorsEnabled: snapshot.typingIndicatorsEnabled,
        deliveryReceiptsEnabled: snapshot.deliveryReceiptsEnabled,
        readReceiptsEnabled: snapshot.readReceiptsEnabled,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setTypingIndicatorsEnabled(bool value) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.setTypingIndicatorsEnabled(value);
      state = state.copyWith(
        isLoading: false,
        typingIndicatorsEnabled: snapshot.typingIndicatorsEnabled,
        deliveryReceiptsEnabled: snapshot.deliveryReceiptsEnabled,
        readReceiptsEnabled: snapshot.readReceiptsEnabled,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setDeliveryReceiptsEnabled(bool value) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.setDeliveryReceiptsEnabled(value);
      state = state.copyWith(
        isLoading: false,
        typingIndicatorsEnabled: snapshot.typingIndicatorsEnabled,
        deliveryReceiptsEnabled: snapshot.deliveryReceiptsEnabled,
        readReceiptsEnabled: snapshot.readReceiptsEnabled,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setReadReceiptsEnabled(bool value) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.setReadReceiptsEnabled(value);
      state = state.copyWith(
        isLoading: false,
        typingIndicatorsEnabled: snapshot.typingIndicatorsEnabled,
        deliveryReceiptsEnabled: snapshot.deliveryReceiptsEnabled,
        readReceiptsEnabled: snapshot.readReceiptsEnabled,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final messagingPreferencesServiceProvider =
    Provider<MessagingPreferencesService>((ref) {
      return MessagingPreferencesServiceImpl();
    });

final messagingPreferencesProvider =
    StateNotifierProvider<
      MessagingPreferencesNotifier,
      MessagingPreferencesState
    >((ref) {
      final service = ref.watch(messagingPreferencesServiceProvider);
      return MessagingPreferencesNotifier(service);
    });
