import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/config/providers/app_bootstrap_provider.dart';
import 'package:iris_chat/config/providers/auth_provider.dart';
import 'package:iris_chat/config/router.dart';
import 'package:iris_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../test_helpers.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(super.repository, AuthState initialState) {
    state = initialState;
  }
}

class _TestBootstrapNotifier extends AppBootstrapNotifier {
  _TestBootstrapNotifier(super.initialState) : super.fake();
}

void main() {
  testWidgets(
    'authenticated users stay on bootstrap route until app data is ready',
    (tester) async {
      final authNotifier = _TestAuthNotifier(
        _MockAuthRepository(),
        const AuthState(
          isAuthenticated: true,
          isInitialized: true,
          pubkeyHex: testPubkeyHex,
          devicePubkeyHex: testPubkeyHex,
        ),
      );
      final bootstrapNotifier = _TestBootstrapNotifier(
        const AppBootstrapState(isLoading: true, isReady: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => authNotifier),
            appBootstrapProvider.overrideWith((ref) => bootstrapNotifier),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(
                theme: createTestTheme(),
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Loading chats...'), findsOneWidget);
    },
  );
}
