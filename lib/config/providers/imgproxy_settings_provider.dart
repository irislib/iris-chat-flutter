import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/imgproxy_service.dart';
import '../../core/services/imgproxy_settings_service.dart';

class ImgproxySettingsState {
  const ImgproxySettingsState({
    this.isLoading = true,
    this.enabled = true,
    this.url = ImgproxyConfig.defaultUrl,
    this.keyHex = ImgproxyConfig.defaultKeyHex,
    this.saltHex = ImgproxyConfig.defaultSaltHex,
    this.error,
  });

  final bool isLoading;
  final bool enabled;
  final String url;
  final String keyHex;
  final String saltHex;
  final String? error;

  ImgproxyConfig get config => ImgproxyConfig(
    enabled: enabled,
    url: url,
    keyHex: keyHex,
    saltHex: saltHex,
  );

  ImgproxySettingsState copyWith({
    bool? isLoading,
    bool? enabled,
    String? url,
    String? keyHex,
    String? saltHex,
    String? error,
    bool clearError = false,
  }) {
    return ImgproxySettingsState(
      isLoading: isLoading ?? this.isLoading,
      enabled: enabled ?? this.enabled,
      url: url ?? this.url,
      keyHex: keyHex ?? this.keyHex,
      saltHex: saltHex ?? this.saltHex,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ImgproxySettingsNotifier extends StateNotifier<ImgproxySettingsState> {
  ImgproxySettingsNotifier(this._service, {bool autoLoad = true})
    : super(const ImgproxySettingsState()) {
    if (autoLoad) {
      Future<void>.microtask(load);
    }
  }

  final ImgproxySettingsService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _service.load();
      state = state.copyWith(
        isLoading: false,
        enabled: snapshot.enabled,
        url: snapshot.url,
        keyHex: snapshot.keyHex,
        saltHex: snapshot.saltHex,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setEnabled(bool value) async {
    await _set((service) => service.setEnabled(value));
  }

  Future<void> setUrl(String value) async {
    await _set((service) => service.setUrl(value));
  }

  Future<void> setKeyHex(String value) async {
    await _set((service) => service.setKeyHex(value));
  }

  Future<void> setSaltHex(String value) async {
    await _set((service) => service.setSaltHex(value));
  }

  Future<void> resetDefaults() async {
    await _set((service) => service.resetDefaults());
  }

  Future<void> _set(
    Future<ImgproxySettingsSnapshot> Function(ImgproxySettingsService service)
    operation,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await operation(_service);
      state = state.copyWith(
        isLoading: false,
        enabled: snapshot.enabled,
        url: snapshot.url,
        keyHex: snapshot.keyHex,
        saltHex: snapshot.saltHex,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final imgproxySettingsServiceProvider = Provider<ImgproxySettingsService>((
  ref,
) {
  return ImgproxySettingsServiceImpl();
});

final imgproxySettingsProvider =
    StateNotifierProvider<ImgproxySettingsNotifier, ImgproxySettingsState>((
      ref,
    ) {
      final service = ref.watch(imgproxySettingsServiceProvider);
      return ImgproxySettingsNotifier(service);
    });
