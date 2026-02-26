import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris_chat/config/providers/auth_provider.dart';
import 'package:iris_chat/config/providers/chat_provider.dart';
import 'package:iris_chat/config/providers/desktop_notification_provider.dart';
import 'package:iris_chat/config/providers/device_manager_provider.dart';
import 'package:iris_chat/config/providers/messaging_preferences_provider.dart';
import 'package:iris_chat/config/providers/mobile_push_provider.dart';
import 'package:iris_chat/config/providers/nostr_provider.dart';
import 'package:iris_chat/config/providers/startup_launch_provider.dart';
import 'package:iris_chat/core/ffi/ndr_ffi.dart';
import 'package:iris_chat/core/services/database_service.dart';
import 'package:iris_chat/core/services/messaging_preferences_service.dart';
import 'package:iris_chat/core/services/nostr_service.dart';
import 'package:iris_chat/core/services/startup_launch_service.dart';
import 'package:iris_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:iris_chat/features/settings/presentation/screens/settings_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr/nostr.dart' as nostr;

import '../test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockNostrService extends Mock implements NostrService {}

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
    this.desktopNotificationsEnabled = true,
    this.mobilePushNotificationsEnabled = true,
  });

  bool typingIndicatorsEnabled;
  bool deliveryReceiptsEnabled;
  bool readReceiptsEnabled;
  bool desktopNotificationsEnabled;
  bool mobilePushNotificationsEnabled;
  int setTypingCalls = 0;
  int setDeliveryCalls = 0;
  int setReadCalls = 0;
  int setDesktopNotificationsCalls = 0;
  int setMobilePushNotificationsCalls = 0;

  @override
  Future<MessagingPreferencesSnapshot> load() async {
    return MessagingPreferencesSnapshot(
      typingIndicatorsEnabled: typingIndicatorsEnabled,
      deliveryReceiptsEnabled: deliveryReceiptsEnabled,
      readReceiptsEnabled: readReceiptsEnabled,
      desktopNotificationsEnabled: desktopNotificationsEnabled,
      mobilePushNotificationsEnabled: mobilePushNotificationsEnabled,
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

  @override
  Future<MessagingPreferencesSnapshot> setDesktopNotificationsEnabled(
    bool value,
  ) async {
    setDesktopNotificationsCalls += 1;
    desktopNotificationsEnabled = value;
    return load();
  }

  @override
  Future<MessagingPreferencesSnapshot> setMobilePushNotificationsEnabled(
    bool value,
  ) async {
    setMobilePushNotificationsCalls += 1;
    mobilePushNotificationsEnabled = value;
    return load();
  }
}

class TestDeviceManagerNotifier extends DeviceManagerNotifier {
  TestDeviceManagerNotifier(
    super.ref,
    super.nostrService,
    super.authRepository, {
    required DeviceManagerState initialState,
    this.registerResult = true,
    this.deleteResult = true,
  }) : super(autoLoad: false) {
    state = initialState;
  }

  bool registerResult;
  bool deleteResult;
  int registerCalls = 0;
  int deleteCalls = 0;
  String? lastDeletedPubkey;

  @override
  Future<void> loadDevices() async {}

  @override
  Future<bool> registerCurrentDevice() async {
    registerCalls += 1;
    return registerResult;
  }

  @override
  Future<bool> deleteDevice(String identityPubkeyHex) async {
    deleteCalls += 1;
    lastDeletedPubkey = identityPubkeyHex;
    return deleteResult;
  }
}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockDatabaseService mockDbService;
  late MockNostrService mockNostrService;
  late FakeStartupLaunchService startupLaunchService;
  late FakeMessagingPreferencesService messagingPreferencesService;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockDbService = MockDatabaseService();
    mockNostrService = MockNostrService();
    startupLaunchService = FakeStartupLaunchService();
    messagingPreferencesService = FakeMessagingPreferencesService();
  });

  Widget buildSettingsScreen({
    String? pubkeyHex,
    bool isAuthenticated = true,
    FakeStartupLaunchService? startupService,
    FakeMessagingPreferencesService? messagingService,
    bool? desktopNotificationsSupported,
    bool? mobilePushSupported,
    DeviceManagerState? deviceManagerState,
    void Function(TestDeviceManagerNotifier notifier)? onDeviceNotifierCreated,
  }) {
    final List<Override> overrides = [
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
      nostrServiceProvider.overrideWithValue(mockNostrService),
      deviceManagerProvider.overrideWith((ref) {
        final notifier = TestDeviceManagerNotifier(
          ref,
          mockNostrService,
          mockAuthRepo,
          initialState:
              deviceManagerState ??
              const DeviceManagerState(isLoading: false, devices: []),
        );
        onDeviceNotifierCreated?.call(notifier);
        return notifier;
      }),
    ];
    if (desktopNotificationsSupported != null) {
      overrides.add(
        desktopNotificationsSupportedProvider.overrideWith(
          (ref) => desktopNotificationsSupported,
        ),
      );
    }
    if (mobilePushSupported != null) {
      overrides.add(
        mobilePushSupportedProvider.overrideWith((ref) => mobilePushSupported),
      );
    }

    return createTestApp(const SettingsScreen(), overrides: overrides);
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
        expect(find.textContaining('npub1'), findsOneWidget);
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

      testWidgets('copies npub format for public key', (tester) async {
        String? copiedText;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'Clipboard.setData') {
                final args = call.arguments as Map<dynamic, dynamic>?;
                copiedText = args?['text']?.toString();
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.copy));
        await tester.pumpAndSettle();

        final expected = nostr.Nip19.encodePubkey(testPubkeyHex) as String;
        expect(copiedText, expected);
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
        expect(find.text('Copy'), findsOneWidget);
      });

      testWidgets('closes export dialog when Cancel tapped', (tester) async {
        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Export Private Key'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be closed
        expect(find.textContaining('Never share it with anyone'), findsNothing);
      });

      testWidgets('copies private key in nsec format when Copy tapped', (
        tester,
      ) async {
        when(
          () => mockAuthRepo.getPrivateKey(),
        ).thenAnswer((_) async => testPrivkeyHex);
        final expectedNsec =
            nostr.Nip19.encodePrivkey(testPrivkeyHex) as String;
        String? copiedText;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'Clipboard.setData') {
                final args = call.arguments as Map<dynamic, dynamic>?;
                copiedText = args?['text']?.toString();
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        await tester.pumpWidget(buildSettingsScreen(pubkeyHex: testPubkeyHex));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Export Private Key'));
        await tester.pumpAndSettle();

        expect(find.text(testPrivkeyHex), findsNothing);
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();
        expect(copiedText, expectedNsec);
      });
    });

    group('devices section', () {
      testWidgets(
        'shows register button when current device is not registered',
        (tester) async {
          await tester.pumpWidget(
            buildSettingsScreen(
              pubkeyHex: testPubkeyHex,
              deviceManagerState: const DeviceManagerState(
                isLoading: false,
                currentDevicePubkeyHex: '1111',
                devices: [
                  FfiDeviceEntry(
                    identityPubkeyHex: '2222',
                    createdAt: 1700000000,
                  ),
                ],
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Register This Device'), findsOneWidget);
        },
      );

      testWidgets('register button calls registerCurrentDevice()', (
        tester,
      ) async {
        TestDeviceManagerNotifier? deviceNotifier;
        await tester.pumpWidget(
          buildSettingsScreen(
            pubkeyHex: testPubkeyHex,
            deviceManagerState: const DeviceManagerState(
              isLoading: false,
              currentDevicePubkeyHex: '1111',
              devices: [],
            ),
            onDeviceNotifierCreated: (notifier) => deviceNotifier = notifier,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Register This Device'));
        await tester.pumpAndSettle();

        expect(deviceNotifier, isNotNull);
        expect(deviceNotifier!.registerCalls, 1);
      });

      testWidgets('delete device action calls notifier after confirmation', (
        tester,
      ) async {
        TestDeviceManagerNotifier? deviceNotifier;
        await tester.pumpWidget(
          buildSettingsScreen(
            pubkeyHex: testPubkeyHex,
            deviceManagerState: const DeviceManagerState(
              isLoading: false,
              currentDevicePubkeyHex: '1111',
              devices: [
                FfiDeviceEntry(
                  identityPubkeyHex: '2222',
                  createdAt: 1700000000,
                ),
              ],
            ),
            onDeviceNotifierCreated: (notifier) => deviceNotifier = notifier,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Delete device'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(deviceNotifier, isNotNull);
        expect(deviceNotifier!.deleteCalls, 1);
        expect(deviceNotifier!.lastDeletedPubkey, '2222');
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
        expect(find.byType(Switch), findsAtLeastNWidgets(4));
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
        await tester.pumpWidget(
          buildSettingsScreen(
            pubkeyHex: testPubkeyHex,
            desktopNotificationsSupported: true,
            mobilePushSupported: true,
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Mobile Push Notifications'),
          300,
        );
        await tester.scrollUntilVisible(find.text('Messaging'), -200);

        expect(find.text('Messaging'), findsOneWidget);
        expect(find.text('Send Typing Indicators'), findsOneWidget);
        expect(find.text('Send Delivery Receipts'), findsOneWidget);
        expect(find.text('Send Read Receipts'), findsOneWidget);
        expect(find.text('Desktop Notifications'), findsOneWidget);
        expect(find.text('Mobile Push Notifications'), findsOneWidget);
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

      testWidgets('updates desktop notifications preference when toggled', (
        tester,
      ) async {
        final service = FakeMessagingPreferencesService(
          desktopNotificationsEnabled: true,
        );
        await tester.pumpWidget(
          buildSettingsScreen(
            pubkeyHex: testPubkeyHex,
            messagingService: service,
            desktopNotificationsSupported: true,
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Desktop Notifications'),
          300,
        );

        await tester.tap(find.text('Desktop Notifications'));
        await tester.pumpAndSettle();

        expect(service.setDesktopNotificationsCalls, 1);
        expect(service.desktopNotificationsEnabled, isFalse);
      });

      testWidgets('updates mobile push preference when toggled', (
        tester,
      ) async {
        final service = FakeMessagingPreferencesService(
          mobilePushNotificationsEnabled: true,
        );
        await tester.pumpWidget(
          buildSettingsScreen(
            pubkeyHex: testPubkeyHex,
            messagingService: service,
            mobilePushSupported: true,
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Mobile Push Notifications'),
          300,
        );

        await tester.tap(find.text('Mobile Push Notifications'));
        await tester.pumpAndSettle();

        expect(service.setMobilePushNotificationsCalls, 1);
        expect(service.mobilePushNotificationsEnabled, isFalse);
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

        final logoutTile = find.widgetWithText(ListTile, 'Logout');
        await tester.scrollUntilVisible(logoutTile, 300);
        await tester.drag(find.byType(ListView), const Offset(0, -140));
        await tester.pumpAndSettle();
        await tester.tap(logoutTile);
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

        final logoutTile = find.widgetWithText(ListTile, 'Logout');
        await tester.scrollUntilVisible(logoutTile, 300);
        await tester.drag(find.byType(ListView), const Offset(0, -140));
        await tester.pumpAndSettle();
        await tester.tap(logoutTile);
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
              nostrServiceProvider.overrideWithValue(mockNostrService),
              deviceManagerProvider.overrideWith((ref) {
                return TestDeviceManagerNotifier(
                  ref,
                  mockNostrService,
                  mockAuthRepo,
                  initialState: const DeviceManagerState(
                    isLoading: false,
                    devices: [],
                  ),
                );
              }),
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
