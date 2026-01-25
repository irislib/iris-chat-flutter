import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_provider.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    @Default(false) bool isLoading,
    String? pubkeyHex,
    String? error,
  }) = _AuthState;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String privkeyHex) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Implement with ndr-ffi
      // 1. Validate key
      // 2. Derive pubkey
      // 3. Store securely
      // 4. Set authenticated
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        // pubkeyHex: derived from privkey
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createIdentity() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Implement with ndr-ffi
      // 1. Call generate_keypair()
      // 2. Store privkey securely
      // 3. Set authenticated
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    // TODO: Clear stored keys
    state = const AuthState();
  }

  Future<void> checkAuth() async {
    // TODO: Check secure storage for existing identity
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
