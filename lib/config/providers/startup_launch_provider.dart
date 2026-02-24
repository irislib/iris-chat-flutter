import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/startup_launch_service.dart';

class StartupLaunchState {
  const StartupLaunchState({
    this.isLoading = true,
    this.isSupported = false,
    this.enabled = true,
    this.error,
  });

  final bool isLoading;
  final bool isSupported;
  final bool enabled;
  final String? error;

  StartupLaunchState copyWith({
    bool? isLoading,
    bool? isSupported,
    bool? enabled,
    String? error,
    bool clearError = false,
  }) {
    return StartupLaunchState(
      isLoading: isLoading ?? this.isLoading,
      isSupported: isSupported ?? this.isSupported,
      enabled: enabled ?? this.enabled,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StartupLaunchNotifier extends StateNotifier<StartupLaunchState> {
  StartupLaunchNotifier(this._service, {bool autoLoad = true})
    : super(const StartupLaunchState()) {
    if (autoLoad) {
      Future<void>.microtask(load);
    }
  }

  final StartupLaunchService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.load();
      state = state.copyWith(
        isLoading: false,
        isSupported: snapshot.isSupported,
        enabled: snapshot.enabled,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        // If load fails after reaching the startup API, keep the control visible.
        isSupported: true,
        error: e.toString(),
      );
    }
  }

  Future<void> setEnabled(bool value) async {
    if (!state.isSupported) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.setEnabled(value);
      state = state.copyWith(
        isLoading: false,
        isSupported: snapshot.isSupported,
        enabled: snapshot.enabled,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final startupLaunchServiceProvider = Provider<StartupLaunchService>((ref) {
  return StartupLaunchServiceImpl();
});

final startupLaunchProvider =
    StateNotifierProvider<StartupLaunchNotifier, StartupLaunchState>((ref) {
      final service = ref.watch(startupLaunchServiceProvider);
      return StartupLaunchNotifier(service);
    });
