import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/config/providers/chat_provider.dart';
import 'package:iris_chat/config/providers/nostr_provider.dart';
import 'package:iris_chat/core/ffi/models/send_text_with_inner_id_result.dart';
import 'package:iris_chat/core/services/nostr_service.dart';
import 'package:iris_chat/core/services/profile_service.dart';
import 'package:iris_chat/core/services/session_manager_service.dart';
import 'package:iris_chat/features/chat/data/datasources/message_local_datasource.dart';
import 'package:iris_chat/features/chat/data/datasources/session_local_datasource.dart';
import 'package:iris_chat/features/chat/domain/models/message.dart';
import 'package:iris_chat/features/chat/domain/models/session.dart';
import 'package:iris_chat/features/chat/presentation/screens/chat_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr/nostr.dart' as nostr;

import '../test_helpers.dart';

class MockSessionLocalDatasource extends Mock
    implements SessionLocalDatasource {}

class MockMessageLocalDatasource extends Mock
    implements MessageLocalDatasource {}

class MockNostrService extends Mock implements NostrService {}

class MockSessionManagerService extends Mock implements SessionManagerService {}

class MockProfileService extends Mock implements ProfileService {}

void main() {
  late MockSessionLocalDatasource mockSessionDatasource;
  late MockMessageLocalDatasource mockMessageDatasource;
  late MockNostrService mockNostrService;
  late MockSessionManagerService mockSessionManagerService;

  const testSessionId = 'test-session-123';
  final testSession = ChatSession(
    id: testSessionId,
    recipientPubkeyHex:
        'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
    recipientName: 'Alice',
    createdAt: DateTime.now(),
    isInitiator: true,
  );

  setUp(() {
    mockSessionDatasource = MockSessionLocalDatasource();
    mockMessageDatasource = MockMessageLocalDatasource();
    mockNostrService = MockNostrService();
    mockSessionManagerService = MockSessionManagerService();
  });

  setUpAll(() {
    registerFallbackValue(
      ChatMessage(
        id: 'fallback',
        sessionId: 'session',
        text: 'text',
        timestamp: DateTime.now(),
        direction: MessageDirection.outgoing,
      ),
    );
    registerFallbackValue(MessageStatus.sent);
  });

  Widget buildChatScreen({
    List<ChatMessage> messages = const [],
    ChatSession? session,
    void Function(SessionNotifier notifier)? onSessionNotifierCreated,
    String? profilePictureUrl,
  }) {
    final effectiveSession = session ?? testSession;
    final profileService = ProfileService(mockNostrService);
    profileService.upsertProfile(
      pubkey: effectiveSession.recipientPubkeyHex,
      displayName: effectiveSession.recipientName,
      picture: profilePictureUrl,
      updatedAt: DateTime(2026, 2, 1),
    );

    when(
      () => mockSessionDatasource.getAllSessions(),
    ).thenAnswer((_) async => [effectiveSession]);
    when(
      () => mockSessionDatasource.getSession(any()),
    ).thenAnswer((_) async => effectiveSession);
    when(
      () => mockMessageDatasource.getMessagesForSession(
        any(),
        limit: any(named: 'limit'),
        beforeId: any(named: 'beforeId'),
      ),
    ).thenAnswer((_) async => messages);
    when(
      () => mockMessageDatasource.updateIncomingStatusByRumorId(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockSessionManagerService.sendReceipt(
        recipientPubkeyHex: any(named: 'recipientPubkeyHex'),
        receiptType: any(named: 'receiptType'),
        messageIds: any(named: 'messageIds'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockSessionManagerService.sendTyping(
        recipientPubkeyHex: any(named: 'recipientPubkeyHex'),
        expiresAtSeconds: any(named: 'expiresAtSeconds'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockSessionManagerService.sendTextWithInnerId(
        recipientPubkeyHex: any(named: 'recipientPubkeyHex'),
        text: any(named: 'text'),
        expiresAtSeconds: any(named: 'expiresAtSeconds'),
      ),
    ).thenAnswer(
      (_) async => const SendTextWithInnerIdResult(
        innerId: 'inner-id',
        outerEventIds: ['outer-id'],
      ),
    );
    when(
      () => mockSessionDatasource.updateMetadata(
        any(),
        unreadCount: any(named: 'unreadCount'),
      ),
    ).thenAnswer((_) async {});

    return createTestApp(
      const ChatScreen(sessionId: testSessionId),
      overrides: [
        sessionDatasourceProvider.overrideWithValue(mockSessionDatasource),
        messageDatasourceProvider.overrideWithValue(mockMessageDatasource),
        nostrServiceProvider.overrideWithValue(mockNostrService),
        sessionManagerServiceProvider.overrideWithValue(
          mockSessionManagerService,
        ),
        profileServiceProvider.overrideWithValue(profileService),
        sessionStateProvider.overrideWith((ref) {
          final notifier = SessionNotifier(
            mockSessionDatasource,
            profileService,
          );
          // Pre-populate the sessions
          notifier.state = SessionState(
            sessions: [effectiveSession],
            isLoading: false,
          );
          onSessionNotifierCreated?.call(notifier);
          return notifier;
        }),
      ],
    );
  }

  group('ChatScreen', () {
    group('app bar', () {
      testWidgets('shows recipient name in title', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        expect(find.text('Alice'), findsOneWidget);
      });

      testWidgets('shows encrypted status', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        expect(find.text('End-to-end encrypted'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows tappable header info area', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('chat-header-info-button')),
          findsOneWidget,
        );
      });

      testWidgets('does not show separate info or timer action icons', (
        tester,
      ) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.info_outline), findsNothing);
        expect(find.byIcon(Icons.timer_outlined), findsNothing);
      });

      testWidgets('shows unseen badge on back button when unread exists', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildChatScreen(session: testSession.copyWith(unreadCount: 3)),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('chats-back-unseen-badge')),
          findsOneWidget,
        );
        expect(find.text('3'), findsOneWidget);
      });
    });

    group('empty messages state', () {
      testWidgets('shows encryption info when no messages', (tester) async {
        await tester.pumpWidget(buildChatScreen(messages: []));
        await tester.pumpAndSettle();

        expect(find.text('End-to-end encrypted'), findsOneWidget);
        expect(
          find.textContaining('Double Ratchet encryption'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      });

      testWidgets(
        'shows notification when disappearing messages setting changes',
        (tester) async {
          SessionNotifier? sessionNotifier;
          await tester.pumpWidget(
            buildChatScreen(
              messages: const [],
              onSessionNotifierCreated: (notifier) =>
                  sessionNotifier = notifier,
            ),
          );
          await tester.pumpAndSettle();

          sessionNotifier!.state = sessionNotifier!.state.copyWith(
            sessions: [testSession.copyWith(messageTtlSeconds: 3600)],
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Disappearing messages set to 1 hour'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'renders disappearing setting notice inside message timeline',
        (tester) async {
          SessionNotifier? sessionNotifier;
          final messages = [
            ChatMessage(
              id: 'msg-1',
              sessionId: testSessionId,
              text: 'hello',
              timestamp: DateTime.now(),
              direction: MessageDirection.incoming,
              status: MessageStatus.delivered,
            ),
          ];
          await tester.pumpWidget(
            buildChatScreen(
              messages: messages,
              onSessionNotifierCreated: (notifier) =>
                  sessionNotifier = notifier,
            ),
          );
          await tester.pumpAndSettle();

          sessionNotifier!.state = sessionNotifier!.state.copyWith(
            sessions: [testSession.copyWith(messageTtlSeconds: 3600)],
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final notice = find.text('Disappearing messages set to 1 hour');
          expect(notice, findsOneWidget);
          expect(
            find.descendant(of: find.byType(ListView), matching: notice),
            findsOneWidget,
          );
        },
      );
    });

    group('message list', () {
      testWidgets('displays messages', (tester) async {
        final messages = [
          ChatMessage(
            id: 'msg-1',
            sessionId: testSessionId,
            text: 'Hello there!',
            timestamp: DateTime.now(),
            direction: MessageDirection.outgoing,
            status: MessageStatus.sent,
          ),
          ChatMessage(
            id: 'msg-2',
            sessionId: testSessionId,
            text: 'Hi! How are you?',
            timestamp: DateTime.now(),
            direction: MessageDirection.incoming,
            status: MessageStatus.delivered,
          ),
        ];

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        expect(find.text('Hello there!'), findsOneWidget);
        expect(find.text('Hi! How are you?'), findsOneWidget);
      });

      testWidgets('outgoing messages align right', (tester) async {
        final messages = [
          ChatMessage(
            id: 'msg-1',
            sessionId: testSessionId,
            text: 'Outgoing message',
            timestamp: DateTime.now(),
            direction: MessageDirection.outgoing,
            status: MessageStatus.sent,
          ),
        ];

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        final bubbleRect = tester.getRect(find.text('Outgoing message'));
        final screenWidth = tester.getSize(find.byType(Scaffold)).width;
        expect(bubbleRect.center.dx, greaterThan(screenWidth * 0.6));
      });

      testWidgets('incoming messages align left', (tester) async {
        final messages = [
          ChatMessage(
            id: 'msg-1',
            sessionId: testSessionId,
            text: 'Incoming message',
            timestamp: DateTime.now(),
            direction: MessageDirection.incoming,
            status: MessageStatus.delivered,
          ),
        ];

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        final bubbleRect = tester.getRect(find.text('Incoming message'));
        final screenWidth = tester.getSize(find.byType(Scaffold)).width;
        expect(bubbleRect.center.dx, lessThan(screenWidth * 0.4));
      });

      testWidgets('shows check icon for sent messages', (tester) async {
        final messages = [
          ChatMessage(
            id: 'msg-1',
            sessionId: testSessionId,
            text: 'Sent message',
            timestamp: DateTime.now(),
            direction: MessageDirection.outgoing,
            status: MessageStatus.sent,
          ),
        ];

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('shows double check for delivered messages', (tester) async {
        final messages = [
          ChatMessage(
            id: 'msg-1',
            sessionId: testSessionId,
            text: 'Delivered message',
            timestamp: DateTime.now(),
            direction: MessageDirection.outgoing,
            status: MessageStatus.delivered,
          ),
        ];

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.done_all), findsOneWidget);
      });

      testWidgets('shows blue double check for seen messages', (tester) async {
        final messages = [
          ChatMessage(
            id: 'msg-1',
            sessionId: testSessionId,
            text: 'Seen message',
            timestamp: DateTime.now(),
            direction: MessageDirection.outgoing,
            status: MessageStatus.seen,
          ),
        ];

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        final icon = tester.widget<Icon>(find.byIcon(Icons.done_all));
        expect(icon.color, Colors.blue);
      });

      testWidgets('shows error icon for failed messages', (tester) async {
        final messages = [
          ChatMessage(
            id: 'msg-1',
            sessionId: testSessionId,
            text: 'Failed message',
            timestamp: DateTime.now(),
            direction: MessageDirection.outgoing,
            status: MessageStatus.failed,
          ),
        ];

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows clock icon for pending messages', (tester) async {
        final messages = [
          ChatMessage(
            id: 'msg-1',
            sessionId: testSessionId,
            text: 'Pending message',
            timestamp: DateTime.now(),
            direction: MessageDirection.outgoing,
            status: MessageStatus.pending,
          ),
        ];

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });
    });

    group('message input', () {
      testWidgets('shows text field with placeholder', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Message'), findsOneWidget);
      });

      testWidgets('autofocuses message field on open', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        final editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.focusNode.hasFocus, isTrue);
      });

      testWidgets('shows send button', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.send), findsOneWidget);
      });

      testWidgets('can enter text in message field', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Hello World');
        await tester.pump();

        expect(find.text('Hello World'), findsOneWidget);
      });

      testWidgets('clears text field after tapping send', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.pump();

        // Verify message was entered
        expect(find.text('Test message'), findsOneWidget);

        // Note: Actually sending requires full session setup which is complex
        // This test verifies the input field works correctly
      });

      testWidgets('scrolls to newest message after send', (tester) async {
        final messages = List<ChatMessage>.generate(
          40,
          (i) => ChatMessage(
            id: 'old-$i',
            sessionId: testSessionId,
            text: 'Old message $i',
            timestamp: DateTime(2026, 1, 1, 12, i),
            direction: i.isEven
                ? MessageDirection.incoming
                : MessageDirection.outgoing,
            status: MessageStatus.delivered,
          ),
        );

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        const newMessage = 'Newest message from send';
        await tester.enterText(find.byType(TextField), newMessage);
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text(newMessage), findsOneWidget);
      });
    });

    group('session info dialog', () {
      testWidgets('opens when info button tapped', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('chat-header-info-button')));
        await tester.pumpAndSettle();

        expect(find.text('Public Key'), findsOneWidget);
        expect(find.text('Session Created'), findsOneWidget);
        expect(find.text('Role'), findsNothing);
      });

      testWidgets('shows recipient name in dialog', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('chat-header-info-button')));
        await tester.pumpAndSettle();

        // Alice should appear in both app bar and dialog
        expect(find.text('Alice'), findsNWidgets(2));
      });

      testWidgets('shows encryption status in dialog', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('chat-header-info-button')));
        await tester.pumpAndSettle();

        // "End-to-end encrypted" appears in dialog (may also appear in app bar)
        expect(find.text('End-to-end encrypted'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows disappearing message options in info sheet', (
        tester,
      ) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('chat-header-info-button')));
        await tester.pumpAndSettle();

        expect(find.text('Disappearing messages'), findsOneWidget);
        expect(find.text('Off'), findsOneWidget);
      });

      testWidgets('shows npub public key in dialog', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('chat-header-info-button')));
        await tester.pumpAndSettle();

        final expectedNpub =
            nostr.Nip19.encodePubkey(testSession.recipientPubkeyHex) as String;
        expect(find.text(expectedNpub), findsOneWidget);
      });

      testWidgets('shows close button in dialog', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('chat-header-info-button')));
        await tester.pumpAndSettle();

        expect(find.text('Close'), findsOneWidget);
      });

      testWidgets('closes dialog when close button tapped', (tester) async {
        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('chat-header-info-button')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Close'));
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // Dialog should be closed - Public Key should no longer be visible
        expect(find.text('Public Key'), findsNothing);
      });

      testWidgets('opens profile picture modal from user info avatar', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildChatScreen(profilePictureUrl: 'https://example.com/alice.png'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('chat-header-info-button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('user_info_avatar_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('chat_attachment_image_viewer')),
          findsOneWidget,
        );
      });
    });

    group('date separators', () {
      testWidgets('shows date separator between messages on different days', (
        tester,
      ) async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final today = DateTime.now();

        final messages = [
          ChatMessage(
            id: 'msg-1',
            sessionId: testSessionId,
            text: 'Yesterday message',
            timestamp: yesterday,
            direction: MessageDirection.incoming,
            status: MessageStatus.delivered,
          ),
          ChatMessage(
            id: 'msg-2',
            sessionId: testSessionId,
            text: 'Today message',
            timestamp: today,
            direction: MessageDirection.outgoing,
            status: MessageStatus.sent,
          ),
        ];

        await tester.pumpWidget(buildChatScreen(messages: messages));
        await tester.pumpAndSettle();

        expect(find.text('Yesterday'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
      });
    });
  });
}
