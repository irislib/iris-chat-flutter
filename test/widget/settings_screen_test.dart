import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris_chat/config/providers/auth_provider.dart';
import 'package:iris_chat/config/providers/chat_provider.dart';
import 'package:iris_chat/config/providers/messaging_preferences_provider.dart';
import 'package:iris_chat/config/providers/startup_launch_provider.dart';
import 'package:iris_chat/core/services/database_service.dart';
import 'package:iris_chat/core/services/messaging_preferences_service.dart';
import 'package:iris_chat/core/services/startup_launch_service.dart';
import 'package:iris_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:iris_chat/features/settings/presentation/screens/settings_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class FakeStartupLaunchService implements StartupLaunchService {
  FakeStartupLaunchService({this.supported = true, this.enabled = true});

  bool supported;
  bool enabled;
  int setEnabledCalls = 0;

  @override
  Future<StartupLaunchSnapshot> load() async {
    return StartupLaunchSnapshot(isSupported: supported, enabled: enabled);
  }

  @override
  Future<StartupLaunchSnapshot> setEnabled(bool value) async {
    setEnabledCalls += 1;
    enabled = value;
    return StartupLaunchSnapshot(isSupported: supported, enabled: enabled);
  }
}

class FakeMessagingPreferencesService implements MessagingPreferencesService {
  FakeMessagingPreferencesService({
    this.typingIndicatorsEnabled = true,
    this.deliveryReceiptsEnabled = true,
    this.readReceiptsEnabled = true,
  });

  bool typingIndicatorsEnabled;
  bool deliveryReceiptsEnabled;
  bool readReceiptsEnabled;
  int setTypingCalls = 0;
  int setDeliveryCalls = 0;
  int setReadCalls = 0;

  @override
  Future<MessagingPreferencesSnapshot> load() async {
    return MessagingPreferencesSnapshot(
      typingIndicatorsEnabled: typingIndicatorsEnabled,
      deliveryReceiptsEnabled: deliveryReceiptsEnabled,
      readReceiptsEnabled: readReceiptsEnabled,
    );
  }

  @override
  Future<MessagingPreferencesSnapshot> setTypingIndicatorsEnabled(
    bool value,
  ) async {
    setTypingCalls += 1;
    typingIndicatorsEnabled = value;
    return load();
  }

  @override
  Future<MessagingPreferencesSnapshot> setDeliveryReceiptsEnabled(
    bool value,
  ) async {
    setDeliveryCalls += 1;
    deliveryReceiptsEnabled = value;
    return load();
  }

  @override
  Future<MessagingPreferencesSnapshot> setReadReceiptsEnabled(
    bool value,
  ) async {
    setReadCalls += 1;
    readReceiptsEnabled = value;
    return load();
  }
}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockDatabaseService mockDbService;
  late FakeStartupLaunchService startupLaunchService;
  late FakeMessagingPreferencesService messagingPreferencesService;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockDbService = MockDatabaseService();
    startupLaunchService = FakeStartupLaunchService();
    messagingPreferencesService = FakeMessagingPreferencesService();
  });

  Widget buildSettingsScreen({
    String? pubkeyHex,
    bool isAuthenticated = true,
    FakeStartupLaunchService? startupService,
    FakeMessagingPreferencesService? messagingService,
  }) {
    return createTestApp(
      const SettingsScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        databaseServiceProvider.overrideWithValue(mockDbService),
        startupLaunchServiceProvider.overrideWithValue(
          startupService ?? startupLaunchService,
        ),
        messagingPreferencesServiceProvider.overrideWithValue(
          messagingService ?? messagingPreferencesService,
        ),
        authStateProvider.overrideWith((ref) {
          final notifier = AuthNotifier(mockAuthRepo);
          notifier.state = AuthState(
            isAuthenticated: isAuthenticated,
            pubkeyHex: pubkeyHex,
            isInitialized: true,
          );
          return notifier;
        }),
      ],
    );
  }

  group('SettingsScreen', () {
    group('app bar', () {
      testWidgets('shows Settings title', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
      });
    });

    group('identity section', () {
      testWidgets('shows Identity section header', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        expect(find.text('Identity'), findsOneWidget);
      });

      testWidgets('shows public key when authenticated', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        expect(find.text('Public Key'), findsOneWidget);
        // Should show truncated pubkey
        expect(find.textContaining('...'), findsOneWidget);
      });

      testWidgets('shows "Not logged in" when no pubkey', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(isAuthenticated: false));
        await tester.pumpAndSettle();

        expect(find.text('Not logged in'), findsOneWidget);
      });

      testWidgets('shows copy button for public key', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        // Find the copy icon in the public key row
        expect(find.byIcon(Icons.copy), findsOneWidget);
      });

      testWidgets('shows person icon for public key row', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person), findsOneWidget);
      });
    });

    group('security section', () {
      testWidgets('shows Security section header', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        expect(find.text('Security'), findsOneWidget);
      });

      testWidgets('shows Export Private Key option', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        expect(find.text('Export Private Key'), findsOneWidget);
        expect(find.text('Backup your key securely'), findsOneWidget);
        expect(find.byIcon(Icons.key), findsOneWidget);
      });

      testWidgets('shows export key confirmation dialog when tapped', (
        tester,
      ) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Export Private Key'));
        await tester.pumpAndSettle();

        expect(
          find.text('Export Private Key'),
          findsNWidgets(2),
        ); // ListTile + Dialog title
        expect(
          find.textContaining('Never share it with anyone'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Show Key'), findsOneWidget);
      });

      testWidgets('closes export dialog when Cancel tapped', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Export Private Key'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be closed
        expect(find.text('Show Key'), findsNothing);
      });

      testWidgets('shows private key when Show Key tapped', (tester) async {
        when(
          () => mockAuthRepo.getPrivateKey(),
        ).thenAnswer((_) async => testPrivkeyHex);

        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Export Private Key'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show Key'));
        await tester.pumpAndSettle();

        expect(find.text('Your Private Key'), findsOneWidget);
        expect(find.text(testPrivkeyHex), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);
      });
    });

    group('about section', () {
      testWidgets('shows About section header', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('About'), 300);
        expect(find.text('About'), findsOneWidget);
      });

      testWidgets('shows version info', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Version'), 300);
        expect(find.text('Version'), findsOneWidget);
        expect(find.text('1.0.0'), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);
      });

      testWidgets('shows source code link', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Source Code'), 300);
        expect(find.text('Source Code'), findsOneWidget);
        expect(
          find.text('github.com/irislib/iris-chat-flutter'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.code), findsOneWidget);
      });
    });

    group('application section', () {
      testWidgets('shows startup toggle when platform is supported', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildSettingsScreen(
            pubkeyHex: testPubkeyHex,
            startupService: FakeStartupLaunchService(
              supported: true,
              enabled: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Application'), 300);
        expect(find.text('Application'), findsOneWidget);
        expect(find.text('Launch on System Startup'), findsOneWidget);
        expect(find.byType(Switch), findsNWidgets(4));
      });

      testWidgets('hides startup toggle when platform is unsupported', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildSettingsScreen(
            pubkeyHex: testPubkeyHex,
            startupService: FakeStartupLaunchService(
              supported: false,
              enabled: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('About'), 300);
        expect(find.text('Launch on System Startup'), findsNothing);
      });

      testWidgets('updates startup toggle when switched', (tester) async {
        final service = FakeStartupLaunchService(
          supported: true,
          enabled: true,
        );
        await tester.pumpWidget(
          buildSettingsScreen(
            pubkeyHex: testPubkeyHex,
            startupService: service,
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Launch on System Startup'),
          300,
        );
        await tester.tap(find.text('Launch on System Startup'));
        await tester.pumpAndSettle();

        expect(service.setEnabledCalls, 1);
        expect(service.enabled, isFalse);
      });
    });

    group('messaging section', () {
      testWidgets('shows messaging toggles', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Send Read Receipts'), 300);

        expect(find.text('Messaging'), findsOneWidget);
        expect(find.text('Send Typing Indicators'), findsOneWidget);
        expect(find.text('Send Delivery Receipts'), findsOneWidget);
        expect(find.text('Send Read Receipts'), findsOneWidget);
      });

      testWidgets('updates typing indicator preference when toggled', (
        tester,
      ) async {
        final service = FakeMessagingPreferencesService(
          typingIndicatorsEnabled: true,
        );
        await tester.pumpWidget(
          buildSettingsScreen(
            pubkeyHex: testPubkeyHex,
            messagingService: service,
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Send Typing Indicators'),
          300,
        );

        await tester.tap(find.text('Send Typing Indicators'));
        await tester.pumpAndSettle();

        expect(service.setTypingCalls, 1);
        expect(service.typingIndicatorsEnabled, isFalse);
      });
    });

    group('danger zone section', () {
      testWidgets('shows Danger Zone section header', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Danger Zone'), 300);
        expect(find.text('Danger Zone'), findsOneWidget);
      });

      testWidgets('shows Logout option with red text', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Logout'), 300);
        expect(find.text('Logout'), findsOneWidget);
        expect(
          find.text('Remove local chats from this device'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.logout), findsOneWidget);
      });

      testWidgets('shows Delete All Data option with red text', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Delete All Data'), 300);

        expect(find.text('Delete All Data'), findsOneWidget);
        expect(find.text('Remove all data including keys'), findsOneWidget);
        expect(find.byIcon(Icons.delete_forever), findsOneWidget);
      });

      testWidgets('shows logout confirmation dialog when Logout tapped', (
        tester,
      ) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Logout'), 300);
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        expect(find.text('Logout?'), findsOneWidget);
        expect(find.textContaining('deletes local chats'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets(
        'shows delete confirmation dialog when Delete All Data tapped',
        (tester) async {
          await tester.pumpWidget(
            buildSettingsScreen(pubkeyHex: testPubkeyHex),
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(find.text('Delete All Data'), 300);

          await tester.tap(find.text('Delete All Data'));
          await tester.pumpAndSettle();

          expect(find.text('Delete All Data?'), findsOneWidget);
          expect(find.textContaining('cannot be undone'), findsOneWidget);
          expect(find.text('Delete Everything'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
        },
      );

      testWidgets('closes logout dialog when Cancel tapped', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Logout'), 300);
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Logout?'), findsNothing);
      });

      testWidgets('calls logout when confirmed', (tester) async {
        when(() => mockDbService.deleteDatabase()).thenAnswer((_) async {});
        when(() => mockAuthRepo.logout()).thenAnswer((_) async {});

        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) =>
                  const Scaffold(body: Text('Login Screen')),
            ),
          ],
        );

        await tester.pumpWidget(
          createTestRouterApp(
            router,
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepo),
              databaseServiceProvider.overrideWithValue(mockDbService),
              startupLaunchServiceProvider.overrideWithValue(
                startupLaunchService,
              ),
              authStateProvider.overrideWith((ref) {
                final notifier = AuthNotifier(mockAuthRepo);
                notifier.state = const AuthState(
                  isAuthenticated: true,
                  pubkeyHex: testPubkeyHex,
                  isInitialized: true,
                );
                return notifier;
              }),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Logout'), 300);
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        // Tap the Logout button in the dialog (second one)
        await tester.tap(find.text('Logout').last);
        await tester.pumpAndSettle();

        verify(() => mockDbService.deleteDatabase()).called(1);
        verify(() => mockAuthRepo.logout()).called(1);
        expect(find.text('Login Screen'), findsOneWidget);
      });
    });

    group('scrolling', () {
      testWidgets('settings screen is scrollable', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });
    });
  });
}
