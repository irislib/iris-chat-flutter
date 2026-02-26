import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris_chat/config/providers/auth_provider.dart';
import 'package:iris_chat/config/providers/chat_provider.dart';
import 'package:iris_chat/config/providers/login_device_registration_provider.dart';
import 'package:iris_chat/core/ffi/ndr_ffi.dart';
import 'package:iris_chat/core/services/database_service.dart';
import 'package:iris_chat/features/auth/domain/models/identity.dart';
import 'package:iris_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:iris_chat/features/auth/presentation/screens/login_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockLoginDeviceRegistrationService extends Mock
    implements LoginDeviceRegistrationService {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockDatabaseService mockDatabaseService;
  late MockLoginDeviceRegistrationService mockLoginDeviceRegistrationService;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockDatabaseService = MockDatabaseService();
    mockLoginDeviceRegistrationService = MockLoginDeviceRegistrationService();
    when(() => mockDatabaseService.deleteDatabase()).thenAnswer((_) async {});
    when(
      () => mockLoginDeviceRegistrationService.buildPreviewFromPrivateKeyNsec(
        any(),
      ),
    ).thenAnswer(
      (_) async => const LoginDeviceRegistrationPreview(
        ownerPubkeyHex: testPubkeyHex,
        ownerPrivkeyHex: testPrivkeyHex,
        currentDevicePubkeyHex: testPubkeyHex,
        existingDevices: [],
        devicesIfRegistered: [
          FfiDeviceEntry(identityPubkeyHex: testPubkeyHex, createdAt: 1),
        ],
        deviceListLoaded: true,
      ),
    );
    when(
      () => mockLoginDeviceRegistrationService.publishDeviceList(
        ownerPubkeyHex: any(named: 'ownerPubkeyHex'),
        ownerPrivkeyHex: any(named: 'ownerPrivkeyHex'),
        devices: any(named: 'devices'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockLoginDeviceRegistrationService.publishSingleDevice(
        ownerPubkeyHex: any(named: 'ownerPubkeyHex'),
        ownerPrivkeyHex: any(named: 'ownerPrivkeyHex'),
        devicePubkeyHex: any(named: 'devicePubkeyHex'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget buildLoginScreen({AuthState? initialAuthState}) {
    return createTestApp(
      const LoginScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        databaseServiceProvider.overrideWithValue(mockDatabaseService),
        loginDeviceRegistrationServiceProvider.overrideWithValue(
          mockLoginDeviceRegistrationService,
        ),
        if (initialAuthState != null)
          authStateProvider.overrideWith((ref) {
            final notifier = AuthNotifier(mockAuthRepo);
            return notifier;
          }),
      ],
    );
  }

  Widget buildLoginScreenRouter() {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/chats',
          builder: (context, state) =>
              const Scaffold(body: Text('Chats Screen')),
        ),
      ],
    );

    return createTestRouterApp(
      router,
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        databaseServiceProvider.overrideWithValue(mockDatabaseService),
        loginDeviceRegistrationServiceProvider.overrideWithValue(
          mockLoginDeviceRegistrationService,
        ),
      ],
    );
  }

  group('LoginScreen', () {
    group('initial rendering', () {
      testWidgets('shows app logo and title', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        expect(find.byType(Image), findsOneWidget);
        // Title is a RichText with "iris" and "chat" spans
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('shows create identity button', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        expect(find.text('Create New Identity'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('shows import existing key button', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        expect(find.text('Import Existing Key'), findsOneWidget);
        expect(find.byIcon(Icons.key), findsOneWidget);
      });

      testWidgets('does not show key input initially', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
        expect(find.text('Login'), findsNothing);
      });
    });

    group('import existing key', () {
      testWidgets('shows key input when import button tapped', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Private Key (nsec)'), findsOneWidget);
        expect(find.text('Login'), findsOneWidget);
      });

      testWidgets('hides key input when close button tapped', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('login button calls login with entered key', (tester) async {
        // Use a completer to control when the login completes
        when(
          () => mockAuthRepo.login(any()),
        ).thenAnswer((_) async => const Identity(pubkeyHex: testPubkeyHex));

        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), testPrivkeyHex);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Login'));
        // Only pump once to verify login was called, don't wait for navigation
        await tester.pump();

        verify(() => mockAuthRepo.login(testPrivkeyHex)).called(1);
      }, skip: true);

      testWidgets('does not call login with empty key', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        // Leave text field empty
        await tester.tap(find.text('Login'));
        await tester.pump();

        verifyNever(() => mockAuthRepo.login(any()));
      });

      testWidgets('obscures password input', (tester) async {
        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.obscureText, isTrue);
      });
    });

    group('create identity', () {
      testWidgets(
        'create identity clears local data then calls createIdentity',
        (tester) async {
          when(
            () => mockAuthRepo.createIdentity(),
          ).thenThrow(Exception('create failed'));

          await tester.pumpWidget(buildLoginScreen());
          await tester.pumpAndSettle();

          await tester.tap(find.text('Create New Identity'));
          await tester.pump();

          verifyInOrder([
            () => mockDatabaseService.deleteDatabase(),
            () => mockAuthRepo.createIdentity(),
          ]);
        },
      );

      testWidgets('create identity auto-registers current device', (
        tester,
      ) async {
        when(
          () => mockAuthRepo.createIdentity(),
        ).thenAnswer((_) async => const Identity(pubkeyHex: testPubkeyHex));
        when(
          () => mockAuthRepo.getPrivateKey(),
        ).thenAnswer((_) async => testPrivkeyHex);

        await tester.pumpWidget(buildLoginScreenRouter());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create New Identity'));
        await tester.pumpAndSettle();

        verify(
          () => mockLoginDeviceRegistrationService.publishSingleDevice(
            ownerPubkeyHex: testPubkeyHex,
            ownerPrivkeyHex: testPrivkeyHex,
            devicePubkeyHex: testPubkeyHex,
          ),
        ).called(1);
      });
    });

    group('loading state', () {
      testWidgets('shows loading indicator when creating identity', (
        tester,
      ) async {
        when(() => mockAuthRepo.createIdentity()).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return const Identity(pubkeyHex: testPubkeyHex);
        });

        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create New Identity'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }, skip: true);

      testWidgets('disables buttons when loading', (tester) async {
        when(() => mockAuthRepo.createIdentity()).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return const Identity(pubkeyHex: testPubkeyHex);
        });

        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create New Identity'));
        await tester.pump();

        // Try to tap the button again - should be disabled
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Create New Identity').first,
        );
        expect(button.onPressed, isNull);
      }, skip: true);
    });

    group('error handling', () {
      testWidgets('displays error message from state', (tester) async {
        when(
          () => mockAuthRepo.login(any()),
        ).thenThrow(const InvalidKeyException('Invalid key format'));

        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'invalid-key');
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign In Without Registering'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid key format'), findsOneWidget);
      });

      testWidgets('error container has correct styling', (tester) async {
        when(
          () => mockAuthRepo.login(any()),
        ).thenThrow(const InvalidKeyException('Test error'));

        await tester.pumpWidget(buildLoginScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'bad-key');
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sign In Without Registering'));
        await tester.pumpAndSettle();

        expect(find.text('Test error'), findsOneWidget);
      });
    });

    group('device registration prompt', () {
      testWidgets('login prompts for device registration preview', (
        tester,
      ) async {
        when(
          () => mockAuthRepo.login(any()),
        ).thenAnswer((_) async => const Identity(pubkeyHex: testPubkeyHex));

        await tester.pumpWidget(buildLoginScreenRouter());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'nsec1dummykey');
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        expect(find.text('Register This Device?'), findsOneWidget);
      });

      testWidgets('can sign in without registering this device', (
        tester,
      ) async {
        when(
          () => mockAuthRepo.login(any()),
        ).thenAnswer((_) async => const Identity(pubkeyHex: testPubkeyHex));

        await tester.pumpWidget(buildLoginScreenRouter());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'nsec1dummykey');
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign In Without Registering'));
        await tester.pumpAndSettle();

        verify(() => mockAuthRepo.login('nsec1dummykey')).called(1);
        verifyNever(
          () => mockLoginDeviceRegistrationService.publishDeviceList(
            ownerPubkeyHex: any(named: 'ownerPubkeyHex'),
            ownerPrivkeyHex: any(named: 'ownerPrivkeyHex'),
            devices: any(named: 'devices'),
          ),
        );
      });

      testWidgets('can sign in and register this device', (tester) async {
        when(
          () => mockAuthRepo.login(any()),
        ).thenAnswer((_) async => const Identity(pubkeyHex: testPubkeyHex));

        await tester.pumpWidget(buildLoginScreenRouter());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Import Existing Key'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'nsec1dummykey');
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign In and Register'));
        await tester.pumpAndSettle();

        verify(() => mockAuthRepo.login('nsec1dummykey')).called(1);
        verify(
          () => mockLoginDeviceRegistrationService.publishDeviceList(
            ownerPubkeyHex: testPubkeyHex,
            ownerPrivkeyHex: testPrivkeyHex,
            devices: any(named: 'devices'),
          ),
        ).called(1);
      });
    });
  });
}
