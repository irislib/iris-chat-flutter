# Iris Chat Flutter - TDD Implementation Plan

End-to-end encrypted chat app using Nostr Double Ratchet protocol via ndr-ffi.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Screens   │  │   Widgets   │  │  Providers  │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                         Domain Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Models    │  │ Repositories│  │  Use Cases  │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                          Data Layer                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   ndr-ffi   │  │   SQLite    │  │   Nostr     │              │
│  │  (Rust FFI) │  │  (Storage)  │  │  (Relays)   │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

- **State Management**: Riverpod + Freezed (immutable state)
- **Navigation**: GoRouter
- **Storage**: SQLite (messages/sessions) + flutter_secure_storage (keys)
- **Encryption**: ndr-ffi (Rust FFI via UniFFI)
- **Nostr**: nostr package + custom relay client
- **Testing**: flutter_test + mocktail

---

## Phase 1: Core FFI Integration

### 1.1 ndr-ffi Dart Bindings

**Goal**: Create Dart wrapper for ndr-ffi Rust library

**Files**:
- `lib/core/ffi/ndr_ffi.dart` - Main FFI interface
- `lib/core/ffi/models/` - FFI data models

**Tests** (write first):
```dart
// test/unit/core/ffi/ndr_ffi_test.dart

group('NdrFfi', () {
  test('generateKeypair returns valid hex keys', () {
    final keypair = NdrFfi.generateKeypair();
    expect(keypair.publicKeyHex.length, 64);
    expect(keypair.privateKeyHex.length, 64);
  });

  test('createInvite returns serializable invite', () {
    final keypair = NdrFfi.generateKeypair();
    final invite = NdrFfi.createInvite(pubkeyHex: keypair.publicKeyHex);
    expect(invite.toUrl('https://iris.to'), startsWith('https://iris.to'));
  });

  test('acceptInvite creates session', () {
    // Create invite as Alice
    final alice = NdrFfi.generateKeypair();
    final invite = NdrFfi.createInvite(pubkeyHex: alice.publicKeyHex);

    // Accept as Bob
    final bob = NdrFfi.generateKeypair();
    final result = NdrFfi.acceptInvite(
      inviteUrl: invite.toUrl('https://iris.to'),
      pubkeyHex: bob.publicKeyHex,
      privkeyHex: bob.privateKeyHex,
    );

    expect(result.session, isNotNull);
    expect(result.responseEventJson, isNotEmpty);
  });

  test('session send/decrypt roundtrip', () {
    // Setup: create session between Alice and Bob
    final (aliceSession, bobSession) = createTestSessionPair();

    // Alice sends message
    final sendResult = aliceSession.sendText('Hello Bob!');
    expect(sendResult.outerEventJson, isNotEmpty);

    // Bob decrypts message
    final decryptResult = bobSession.decryptEvent(sendResult.outerEventJson);
    expect(decryptResult.plaintext, 'Hello Bob!');
  });

  test('session state serialization roundtrip', () {
    final (session, _) = createTestSessionPair();

    final stateJson = session.stateJson();
    final restored = NdrFfi.sessionFromState(stateJson);

    expect(restored.canSend(), session.canSend());
  });
});
```

**Implementation**:
```dart
// lib/core/ffi/ndr_ffi.dart

class NdrFfi {
  static FfiKeypair generateKeypair() { ... }
  static InviteHandle createInvite({required String pubkeyHex, String? deviceId, int? maxUses}) { ... }
  static InviteAcceptResult acceptInvite({required String inviteUrl, required String pubkeyHex, required String privkeyHex}) { ... }
  static SessionHandle sessionFromState(String stateJson) { ... }
}

class InviteHandle {
  String toUrl(String root);
  String toEventJson();
  String serialize();
  static InviteHandle deserialize(String json);
  static InviteHandle fromUrl(String url);
  InviteAcceptResult accept(String pubkeyHex, String privkeyHex, {String? deviceId});
  String get inviterPubkeyHex;
  String get sharedSecretHex;
}

class SessionHandle {
  bool canSend();
  SendResult sendText(String text);
  DecryptResult decryptEvent(String eventJson);
  String stateJson();
  bool isDrMessage(String eventJson);
}
```

### 1.2 FFI Integration Tests

**Files**:
- `test/integration/ffi_integration_test.dart`

**Tests**:
```dart
group('FFI Integration', () {
  test('full invite flow with Nostr events', () {
    // 1. Alice creates invite
    // 2. Bob accepts invite (produces Nostr event)
    // 3. Alice receives accept event, creates session
    // 4. Both can exchange messages
  });

  test('session survives app restart via serialization', () {
    // 1. Create session
    // 2. Exchange messages
    // 3. Serialize session state
    // 4. Restore session
    // 5. Continue conversation
  });
});
```

---

## Phase 2: Identity & Storage

### 2.1 Secure Key Storage

**Goal**: Securely store private keys and identity

**Files**:
- `lib/core/services/secure_storage_service.dart`
- `lib/features/auth/data/datasources/identity_storage.dart`

**Tests**:
```dart
// test/unit/core/services/secure_storage_service_test.dart

group('SecureStorageService', () {
  late SecureStorageService service;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(mockStorage);
  });

  test('savePrivateKey stores encrypted key', () async {
    await service.savePrivateKey('abc123...');
    verify(() => mockStorage.write(key: 'privkey', value: any())).called(1);
  });

  test('getPrivateKey returns stored key', () async {
    when(() => mockStorage.read(key: 'privkey')).thenAnswer((_) async => 'abc123');
    final result = await service.getPrivateKey();
    expect(result, 'abc123');
  });

  test('hasIdentity returns true when key exists', () async {
    when(() => mockStorage.containsKey(key: 'privkey')).thenAnswer((_) async => true);
    expect(await service.hasIdentity(), true);
  });

  test('clearIdentity removes all keys', () async {
    await service.clearIdentity();
    verify(() => mockStorage.deleteAll()).called(1);
  });
});
```

### 2.2 Auth Repository

**Files**:
- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`

**Tests**:
```dart
// test/unit/features/auth/data/repositories/auth_repository_test.dart

group('AuthRepository', () {
  test('createIdentity generates and stores keypair', () async {
    final repo = AuthRepositoryImpl(mockStorage, mockNdrFfi);

    when(() => mockNdrFfi.generateKeypair()).thenReturn(testKeypair);

    final result = await repo.createIdentity();

    expect(result.pubkeyHex, testKeypair.publicKeyHex);
    verify(() => mockStorage.savePrivateKey(testKeypair.privateKeyHex)).called(1);
  });

  test('login validates and stores provided key', () async {
    final repo = AuthRepositoryImpl(mockStorage, mockNdrFfi);

    await repo.login(validPrivkeyHex);

    verify(() => mockStorage.savePrivateKey(validPrivkeyHex)).called(1);
  });

  test('login throws on invalid key format', () async {
    final repo = AuthRepositoryImpl(mockStorage, mockNdrFfi);

    expect(
      () => repo.login('invalid'),
      throwsA(isA<InvalidKeyException>()),
    );
  });

  test('getCurrentIdentity returns stored identity', () async {
    when(() => mockStorage.getPrivateKey()).thenAnswer((_) async => validPrivkeyHex);

    final identity = await repo.getCurrentIdentity();

    expect(identity, isNotNull);
    expect(identity!.pubkeyHex.length, 64);
  });
});
```

### 2.3 Auth State Provider

**Files**:
- `lib/config/providers/auth_provider.dart`

**Tests**:
```dart
// test/unit/config/providers/auth_provider_test.dart

group('AuthNotifier', () {
  test('initial state is not authenticated', () {
    final notifier = AuthNotifier(mockAuthRepo);
    expect(notifier.state.isAuthenticated, false);
  });

  test('createIdentity sets authenticated on success', () async {
    when(() => mockAuthRepo.createIdentity())
        .thenAnswer((_) async => testIdentity);

    final notifier = AuthNotifier(mockAuthRepo);
    await notifier.createIdentity();

    expect(notifier.state.isAuthenticated, true);
    expect(notifier.state.pubkeyHex, testIdentity.pubkeyHex);
  });

  test('login sets error on failure', () async {
    when(() => mockAuthRepo.login(any()))
        .thenThrow(InvalidKeyException('bad key'));

    final notifier = AuthNotifier(mockAuthRepo);
    await notifier.login('bad');

    expect(notifier.state.isAuthenticated, false);
    expect(notifier.state.error, isNotNull);
  });

  test('checkAuth restores session from storage', () async {
    when(() => mockAuthRepo.getCurrentIdentity())
        .thenAnswer((_) async => testIdentity);

    final notifier = AuthNotifier(mockAuthRepo);
    await notifier.checkAuth();

    expect(notifier.state.isAuthenticated, true);
  });

  test('logout clears state', () async {
    final notifier = AuthNotifier(mockAuthRepo);
    notifier.state = AuthState(isAuthenticated: true, pubkeyHex: 'abc');

    await notifier.logout();

    expect(notifier.state.isAuthenticated, false);
    expect(notifier.state.pubkeyHex, isNull);
  });
});
```

---

## Phase 3: Invite System

### 3.1 Invite Models

**Files**:
- `lib/features/invite/domain/models/invite.dart`

**Tests**:
```dart
// test/unit/features/invite/domain/models/invite_test.dart

group('Invite', () {
  test('fromUrl parses valid invite URL', () {
    const url = 'https://iris.to/invite/abc123...';
    final invite = Invite.fromUrl(url);
    expect(invite, isNotNull);
  });

  test('fromUrl returns null for invalid URL', () {
    const url = 'https://other.com/invalid';
    final invite = Invite.fromUrl(url);
    expect(invite, isNull);
  });

  test('toUrl generates shareable link', () {
    final invite = Invite.create(pubkeyHex: 'abc123...');
    final url = invite.toUrl();
    expect(url, startsWith('https://iris.to/invite/'));
  });

  test('serialization roundtrip preserves data', () {
    final invite = Invite.create(pubkeyHex: 'abc123...');
    final json = invite.toJson();
    final restored = Invite.fromJson(json);
    expect(restored.id, invite.id);
  });
});
```

### 3.2 Invite Repository

**Files**:
- `lib/features/invite/domain/repositories/invite_repository.dart`
- `lib/features/invite/data/repositories/invite_repository_impl.dart`
- `lib/features/invite/data/datasources/invite_local_datasource.dart`

**Tests**:
```dart
// test/unit/features/invite/data/repositories/invite_repository_test.dart

group('InviteRepository', () {
  test('createInvite stores and returns invite', () async {
    final repo = InviteRepositoryImpl(mockDatasource, mockNdrFfi, mockIdentity);

    final invite = await repo.createInvite(label: 'Test invite');

    expect(invite.label, 'Test invite');
    verify(() => mockDatasource.saveInvite(any())).called(1);
  });

  test('getActiveInvites returns non-expired invites', () async {
    when(() => mockDatasource.getAllInvites())
        .thenAnswer((_) async => [activeInvite, expiredInvite]);

    final invites = await repo.getActiveInvites();

    expect(invites.length, 1);
    expect(invites.first.id, activeInvite.id);
  });

  test('acceptInvite creates session and publishes event', () async {
    final repo = InviteRepositoryImpl(mockDatasource, mockNdrFfi, mockIdentity);

    final result = await repo.acceptInvite(inviteUrl);

    expect(result.session, isNotNull);
    verify(() => mockNostrService.publishEvent(any())).called(1);
  });

  test('deleteInvite removes from storage', () async {
    await repo.deleteInvite('invite-123');
    verify(() => mockDatasource.deleteInvite('invite-123')).called(1);
  });
});
```

### 3.3 Invite Provider

**Files**:
- `lib/config/providers/invite_provider.dart`

**Tests**:
```dart
// test/unit/config/providers/invite_provider_test.dart

group('InviteNotifier', () {
  test('createInvite adds to state', () async {
    final notifier = InviteNotifier(mockInviteRepo);

    when(() => mockInviteRepo.createInvite(label: any(named: 'label')))
        .thenAnswer((_) async => testInvite);

    await notifier.createInvite(label: 'New');

    expect(notifier.state.invites, contains(testInvite));
  });

  test('acceptInvite navigates to chat on success', () async {
    final notifier = InviteNotifier(mockInviteRepo);

    when(() => mockInviteRepo.acceptInvite(any()))
        .thenAnswer((_) async => AcceptResult(session: testSession));

    final result = await notifier.acceptInvite(inviteUrl);

    expect(result.sessionId, testSession.id);
  });

  test('loadInvites populates state from storage', () async {
    when(() => mockInviteRepo.getActiveInvites())
        .thenAnswer((_) async => [invite1, invite2]);

    final notifier = InviteNotifier(mockInviteRepo);
    await notifier.loadInvites();

    expect(notifier.state.invites.length, 2);
  });
});
```

---

## Phase 4: Session & Messaging

### 4.1 Session Models

**Files**:
- `lib/features/chat/domain/models/session.dart`
- `lib/features/chat/domain/models/message.dart`

**Tests**:
```dart
// test/unit/features/chat/domain/models/session_test.dart

group('ChatSession', () {
  test('fromHandle wraps FFI session', () {
    final session = ChatSession.fromHandle(
      handle: mockSessionHandle,
      recipientPubkey: 'abc123',
    );
    expect(session.recipientPubkey, 'abc123');
  });

  test('canSend delegates to handle', () {
    when(() => mockSessionHandle.canSend()).thenReturn(true);
    expect(session.canSend, true);
  });

  test('serialization preserves session state', () {
    final json = session.toJson();
    final restored = ChatSession.fromJson(json);
    expect(restored.id, session.id);
    expect(restored.recipientPubkey, session.recipientPubkey);
  });
});

// test/unit/features/chat/domain/models/message_test.dart

group('ChatMessage', () {
  test('creates outgoing message with pending status', () {
    final msg = ChatMessage.outgoing(
      sessionId: 'session-1',
      text: 'Hello',
    );
    expect(msg.direction, MessageDirection.outgoing);
    expect(msg.status, MessageStatus.pending);
  });

  test('creates incoming message with delivered status', () {
    final msg = ChatMessage.incoming(
      sessionId: 'session-1',
      text: 'Hi there',
      eventId: 'event-123',
    );
    expect(msg.direction, MessageDirection.incoming);
    expect(msg.status, MessageStatus.delivered);
  });
});
```

### 4.2 Message Storage

**Files**:
- `lib/features/chat/data/datasources/message_local_datasource.dart`
- `lib/features/chat/data/datasources/session_local_datasource.dart`

**Tests**:
```dart
// test/unit/features/chat/data/datasources/message_local_datasource_test.dart

group('MessageLocalDatasource', () {
  late MessageLocalDatasource datasource;
  late Database db;

  setUp(() async {
    db = await openTestDatabase();
    datasource = MessageLocalDatasource(db);
  });

  test('saveMessage inserts into database', () async {
    await datasource.saveMessage(testMessage);

    final messages = await datasource.getMessagesForSession('session-1');
    expect(messages.length, 1);
    expect(messages.first.id, testMessage.id);
  });

  test('getMessagesForSession returns ordered by timestamp', () async {
    await datasource.saveMessage(message1); // older
    await datasource.saveMessage(message2); // newer

    final messages = await datasource.getMessagesForSession('session-1');

    expect(messages.first.timestamp.isBefore(messages.last.timestamp), true);
  });

  test('updateMessageStatus updates existing message', () async {
    await datasource.saveMessage(testMessage);
    await datasource.updateMessageStatus(testMessage.id, MessageStatus.sent);

    final messages = await datasource.getMessagesForSession('session-1');
    expect(messages.first.status, MessageStatus.sent);
  });

  test('deleteMessagesForSession removes all session messages', () async {
    await datasource.saveMessage(testMessage);
    await datasource.deleteMessagesForSession('session-1');

    final messages = await datasource.getMessagesForSession('session-1');
    expect(messages, isEmpty);
  });
});
```

### 4.3 Chat Repository

**Files**:
- `lib/features/chat/domain/repositories/chat_repository.dart`
- `lib/features/chat/data/repositories/chat_repository_impl.dart`

**Tests**:
```dart
// test/unit/features/chat/data/repositories/chat_repository_test.dart

group('ChatRepository', () {
  test('sendMessage encrypts and publishes', () async {
    final repo = ChatRepositoryImpl(
      sessionDatasource: mockSessionDs,
      messageDatasource: mockMessageDs,
      nostrService: mockNostrService,
    );

    when(() => mockSessionDs.getSession('session-1'))
        .thenAnswer((_) async => testSession);

    final message = await repo.sendMessage(
      sessionId: 'session-1',
      text: 'Hello!',
    );

    expect(message.text, 'Hello!');
    expect(message.status, MessageStatus.pending);
    verify(() => mockNostrService.publishEvent(any())).called(1);
  });

  test('receiveMessage decrypts and stores', () async {
    when(() => mockSessionDs.getSession('session-1'))
        .thenAnswer((_) async => testSession);
    when(() => testSession.handle.decryptEvent(any()))
        .thenReturn(DecryptResult(plaintext: 'Hello!', innerEventJson: '{}'));

    final message = await repo.receiveMessage(
      sessionId: 'session-1',
      eventJson: encryptedEventJson,
    );

    expect(message.text, 'Hello!');
    verify(() => mockMessageDs.saveMessage(any())).called(1);
  });

  test('getSessions returns all active sessions', () async {
    when(() => mockSessionDs.getAllSessions())
        .thenAnswer((_) async => [session1, session2]);

    final sessions = await repo.getSessions();
    expect(sessions.length, 2);
  });

  test('getMessages returns paginated messages', () async {
    when(() => mockMessageDs.getMessagesForSession('session-1', limit: 50))
        .thenAnswer((_) async => testMessages);

    final messages = await repo.getMessages('session-1', limit: 50);
    expect(messages.length, lessThanOrEqualTo(50));
  });
});
```

### 4.4 Chat Provider

**Files**:
- `lib/config/providers/chat_provider.dart`
- `lib/config/providers/session_provider.dart`

**Tests**:
```dart
// test/unit/config/providers/chat_provider_test.dart

group('ChatNotifier', () {
  test('sendMessage adds optimistic message to state', () async {
    final notifier = ChatNotifier(mockChatRepo);

    when(() => mockChatRepo.sendMessage(sessionId: any(named: 'sessionId'), text: any(named: 'text')))
        .thenAnswer((_) async => testMessage);

    await notifier.sendMessage('session-1', 'Hello!');

    expect(notifier.state.messages['session-1'], contains(testMessage));
  });

  test('loadMessages populates state for session', () async {
    when(() => mockChatRepo.getMessages('session-1'))
        .thenAnswer((_) async => [msg1, msg2]);

    final notifier = ChatNotifier(mockChatRepo);
    await notifier.loadMessages('session-1');

    expect(notifier.state.messages['session-1']?.length, 2);
  });

  test('receiveMessage adds to state and marks as read', () async {
    final notifier = ChatNotifier(mockChatRepo);

    await notifier.receiveMessage('session-1', encryptedEventJson);

    expect(notifier.state.messages['session-1'], isNotEmpty);
  });
});

// test/unit/config/providers/session_provider_test.dart

group('SessionNotifier', () {
  test('loadSessions populates state', () async {
    when(() => mockChatRepo.getSessions())
        .thenAnswer((_) async => [session1, session2]);

    final notifier = SessionNotifier(mockChatRepo);
    await notifier.loadSessions();

    expect(notifier.state.sessions.length, 2);
  });

  test('createSessionFromInviteAccept adds new session', () async {
    final notifier = SessionNotifier(mockChatRepo);

    await notifier.createSessionFromInviteAccept(acceptResult);

    expect(notifier.state.sessions, isNotEmpty);
  });
});
```

---

## Phase 5: Nostr Integration

### 5.1 Nostr Service

**Files**:
- `lib/core/services/nostr_service.dart`
- `lib/core/services/relay_pool.dart`

**Tests**:
```dart
// test/unit/core/services/nostr_service_test.dart

group('NostrService', () {
  test('publishEvent sends to all connected relays', () async {
    final service = NostrService(mockRelayPool);

    when(() => mockRelayPool.connectedRelays).thenReturn([relay1, relay2]);

    await service.publishEvent(testEvent);

    verify(() => relay1.send(any())).called(1);
    verify(() => relay2.send(any())).called(1);
  });

  test('subscribe creates subscription on relays', () async {
    final service = NostrService(mockRelayPool);

    final stream = service.subscribe(filter: testFilter);

    expect(stream, isA<Stream<NostrEvent>>());
  });

  test('unsubscribe closes subscription', () async {
    final service = NostrService(mockRelayPool);

    final sub = await service.subscribe(filter: testFilter);
    await service.unsubscribe(sub.id);

    verify(() => mockRelayPool.closeSubscription(sub.id)).called(1);
  });
});

// test/unit/core/services/relay_pool_test.dart

group('RelayPool', () {
  test('connect establishes WebSocket connections', () async {
    final pool = RelayPool(mockWebSocketFactory);

    await pool.connect(['wss://relay1.com', 'wss://relay2.com']);

    expect(pool.connectedRelays.length, 2);
  });

  test('reconnects on connection failure', () async {
    final pool = RelayPool(mockWebSocketFactory);

    // Simulate disconnect
    when(() => mockWs.closeCode).thenReturn(1006);

    await pool.connect(['wss://relay1.com']);
    pool.simulateDisconnect('wss://relay1.com');

    // Should attempt reconnect
    await Future.delayed(Duration(seconds: 2));
    verify(() => mockWebSocketFactory.create('wss://relay1.com')).called(2);
  });
});
```

### 5.2 Message Subscription

**Files**:
- `lib/features/chat/data/datasources/message_subscription.dart`

**Tests**:
```dart
// test/unit/features/chat/data/datasources/message_subscription_test.dart

group('MessageSubscription', () {
  test('subscribes to session ephemeral pubkeys', () async {
    final sub = MessageSubscription(mockNostrService, mockSessionDs);

    when(() => mockSessionDs.getEphemeralPubkeys())
        .thenAnswer((_) async => ['pubkey1', 'pubkey2']);

    await sub.startListening();

    verify(() => mockNostrService.subscribe(
      filter: argThat(hasProperty('authors', ['pubkey1', 'pubkey2'])),
    )).called(1);
  });

  test('routes events to correct session handler', () async {
    final sub = MessageSubscription(mockNostrService, mockSessionDs);

    final received = <String>[];
    sub.onMessage = (sessionId, eventJson) => received.add(sessionId);

    await sub.startListening();
    sub.handleEvent(testEvent);

    expect(received, ['session-1']);
  });

  test('updates subscription when sessions change', () async {
    final sub = MessageSubscription(mockNostrService, mockSessionDs);

    await sub.startListening();
    await sub.refreshSubscription();

    verify(() => mockNostrService.subscribe(filter: any(named: 'filter'))).called(2);
  });
});
```

---

## Phase 6: UI Implementation

### 6.1 Login Screen

**Files**:
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/widgets/key_input_field.dart`

**Tests**:
```dart
// test/widget/features/auth/presentation/screens/login_screen_test.dart

group('LoginScreen', () {
  testWidgets('shows create identity button', (tester) async {
    await tester.pumpWidget(createTestApp(LoginScreen()));

    expect(find.text('Create New Identity'), findsOneWidget);
  });

  testWidgets('shows import key option', (tester) async {
    await tester.pumpWidget(createTestApp(LoginScreen()));

    expect(find.text('Import Existing Key'), findsOneWidget);
  });

  testWidgets('create identity navigates to chat list', (tester) async {
    await tester.pumpWidget(createTestApp(LoginScreen()));

    await tester.tap(find.text('Create New Identity'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatListScreen), findsOneWidget);
  });

  testWidgets('import shows key input field', (tester) async {
    await tester.pumpWidget(createTestApp(LoginScreen()));

    await tester.tap(find.text('Import Existing Key'));
    await tester.pump();

    expect(find.byType(KeyInputField), findsOneWidget);
  });

  testWidgets('invalid key shows error', (tester) async {
    await tester.pumpWidget(createTestApp(LoginScreen()));

    await tester.tap(find.text('Import Existing Key'));
    await tester.pump();

    await tester.enterText(find.byType(KeyInputField), 'invalid');
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Invalid private key'), findsOneWidget);
  });
});
```

### 6.2 Chat List Screen

**Files**:
- `lib/features/chat/presentation/screens/chat_list_screen.dart`
- `lib/features/chat/presentation/widgets/chat_list_item.dart`

**Tests**:
```dart
// test/widget/features/chat/presentation/screens/chat_list_screen_test.dart

group('ChatListScreen', () {
  testWidgets('shows empty state when no chats', (tester) async {
    await tester.pumpWidget(createTestApp(
      ChatListScreen(),
      overrides: [sessionProvider.overrideWith((_) => SessionState(sessions: []))],
    ));

    expect(find.text('No conversations yet'), findsOneWidget);
    expect(find.text('Start a new chat'), findsOneWidget);
  });

  testWidgets('shows list of chats', (tester) async {
    await tester.pumpWidget(createTestApp(
      ChatListScreen(),
      overrides: [sessionProvider.overrideWith((_) => SessionState(sessions: [session1, session2]))],
    ));

    expect(find.byType(ChatListItem), findsNWidgets(2));
  });

  testWidgets('tapping chat navigates to chat screen', (tester) async {
    await tester.pumpWidget(createTestApp(ChatListScreen()));

    await tester.tap(find.byType(ChatListItem).first);
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('FAB opens new chat options', (tester) async {
    await tester.pumpWidget(createTestApp(ChatListScreen()));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Create Invite'), findsOneWidget);
    expect(find.text('Scan Invite'), findsOneWidget);
  });

  testWidgets('shows last message preview', (tester) async {
    await tester.pumpWidget(createTestApp(ChatListScreen()));

    expect(find.text('Hello there!'), findsOneWidget); // last message text
  });

  testWidgets('shows unread count badge', (tester) async {
    await tester.pumpWidget(createTestApp(
      ChatListScreen(),
      overrides: [chatProvider.overrideWith((_) => ChatState(unreadCounts: {'session-1': 3}))],
    ));

    expect(find.text('3'), findsOneWidget);
  });
});
```

### 6.3 Chat Screen

**Files**:
- `lib/features/chat/presentation/screens/chat_screen.dart`
- `lib/features/chat/presentation/widgets/message_bubble.dart`
- `lib/features/chat/presentation/widgets/message_input.dart`

**Tests**:
```dart
// test/widget/features/chat/presentation/screens/chat_screen_test.dart

group('ChatScreen', () {
  testWidgets('shows message history', (tester) async {
    await tester.pumpWidget(createTestApp(ChatScreen(sessionId: 'session-1')));

    expect(find.byType(MessageBubble), findsNWidgets(5));
  });

  testWidgets('shows message input at bottom', (tester) async {
    await tester.pumpWidget(createTestApp(ChatScreen(sessionId: 'session-1')));

    expect(find.byType(MessageInput), findsOneWidget);
  });

  testWidgets('sending message adds to list', (tester) async {
    await tester.pumpWidget(createTestApp(ChatScreen(sessionId: 'session-1')));

    await tester.enterText(find.byType(TextField), 'New message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('New message'), findsOneWidget);
  });

  testWidgets('outgoing messages align right', (tester) async {
    await tester.pumpWidget(createTestApp(ChatScreen(sessionId: 'session-1')));

    final outgoingBubble = tester.widget<MessageBubble>(
      find.byType(MessageBubble).first,
    );
    expect(outgoingBubble.alignment, Alignment.centerRight);
  });

  testWidgets('incoming messages align left', (tester) async {
    await tester.pumpWidget(createTestApp(ChatScreen(sessionId: 'session-1')));

    final incomingBubble = tester.widget<MessageBubble>(
      find.byType(MessageBubble).last,
    );
    expect(incomingBubble.alignment, Alignment.centerLeft);
  });

  testWidgets('scrolls to bottom on new message', (tester) async {
    await tester.pumpWidget(createTestApp(ChatScreen(sessionId: 'session-1')));

    // Scroll up
    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pump();

    // Receive new message
    final notifier = tester.read(chatProvider.notifier);
    await notifier.receiveMessage('session-1', newMessageEvent);
    await tester.pumpAndSettle();

    // Should be at bottom
    expect(find.text('New message content'), findsOneWidget);
  });

  testWidgets('shows message status indicators', (tester) async {
    await tester.pumpWidget(createTestApp(ChatScreen(sessionId: 'session-1')));

    expect(find.byIcon(Icons.check), findsWidgets); // sent
    expect(find.byIcon(Icons.done_all), findsWidgets); // delivered
  });
});
```

### 6.4 Invite Screens

**Files**:
- `lib/features/invite/presentation/screens/create_invite_screen.dart`
- `lib/features/invite/presentation/screens/scan_invite_screen.dart`
- `lib/features/invite/presentation/widgets/qr_code_display.dart`

**Tests**:
```dart
// test/widget/features/invite/presentation/screens/create_invite_screen_test.dart

group('CreateInviteScreen', () {
  testWidgets('shows QR code for invite', (tester) async {
    await tester.pumpWidget(createTestApp(CreateInviteScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('copy button copies invite URL', (tester) async {
    await tester.pumpWidget(createTestApp(CreateInviteScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();

    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('share button opens share sheet', (tester) async {
    await tester.pumpWidget(createTestApp(CreateInviteScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.share));
    // Share sheet is platform-specific, just verify no error
  });

  testWidgets('shows invite label input', (tester) async {
    await tester.pumpWidget(createTestApp(CreateInviteScreen()));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Label (optional)'), findsOneWidget);
  });
});

// test/widget/features/invite/presentation/screens/scan_invite_screen_test.dart

group('ScanInviteScreen', () {
  testWidgets('shows camera preview', (tester) async {
    await tester.pumpWidget(createTestApp(ScanInviteScreen()));

    expect(find.byType(MobileScanner), findsOneWidget);
  });

  testWidgets('shows paste option', (tester) async {
    await tester.pumpWidget(createTestApp(ScanInviteScreen()));

    expect(find.text('Paste invite link'), findsOneWidget);
  });

  testWidgets('valid QR navigates to chat', (tester) async {
    await tester.pumpWidget(createTestApp(ScanInviteScreen()));

    // Simulate QR detection
    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    scanner.onDetect?.call(BarcodeCapture(barcodes: [validInviteBarcode]));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('invalid QR shows error', (tester) async {
    await tester.pumpWidget(createTestApp(ScanInviteScreen()));

    // Simulate invalid QR
    final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
    scanner.onDetect?.call(BarcodeCapture(barcodes: [invalidBarcode]));
    await tester.pump();

    expect(find.text('Invalid invite'), findsOneWidget);
  });
});
```

---

## Phase 7: Integration & E2E Tests

### 7.1 Full Flow Integration Tests

**Files**:
- `test/integration/full_chat_flow_test.dart`

**Tests**:
```dart
// test/integration/full_chat_flow_test.dart

group('Full Chat Flow', () {
  test('Alice and Bob can exchange messages', () async {
    // 1. Alice creates identity
    final aliceAuth = AuthNotifier(realAuthRepo);
    await aliceAuth.createIdentity();

    // 2. Alice creates invite
    final aliceInvite = InviteNotifier(realInviteRepo);
    final invite = await aliceInvite.createInvite(label: 'For Bob');

    // 3. Bob creates identity
    final bobAuth = AuthNotifier(realAuthRepo);
    await bobAuth.createIdentity();

    // 4. Bob accepts invite
    final bobInvite = InviteNotifier(realInviteRepo);
    final acceptResult = await bobInvite.acceptInvite(invite.toUrl());

    // 5. Alice receives acceptance (via Nostr event)
    // ... simulate Nostr event delivery

    // 6. Both have sessions
    expect(aliceSession, isNotNull);
    expect(bobSession, isNotNull);

    // 7. Bob sends message
    await bobChat.sendMessage(bobSession.id, 'Hello Alice!');

    // 8. Alice receives message
    // ... simulate Nostr event delivery
    expect(aliceChat.state.messages[aliceSession.id]?.last.text, 'Hello Alice!');

    // 9. Alice replies
    await aliceChat.sendMessage(aliceSession.id, 'Hi Bob!');

    // 10. Bob receives reply
    // ... simulate Nostr event delivery
    expect(bobChat.state.messages[bobSession.id]?.last.text, 'Hi Bob!');
  });

  test('session persists across app restart', () async {
    // 1. Create session and exchange messages
    // 2. Serialize all state
    // 3. Clear memory
    // 4. Restore from storage
    // 5. Verify can continue conversation
  });

  test('handles offline/online transitions', () async {
    // 1. Go offline
    // 2. Queue messages
    // 3. Come online
    // 4. Messages send successfully
    // 5. Receive queued incoming messages
  });
});
```

---

## Implementation Order

### Sprint 1: Foundation
1. [ ] Phase 1.1: ndr-ffi Dart bindings
2. [ ] Phase 1.2: FFI integration tests
3. [ ] Phase 2.1: Secure key storage
4. [ ] Phase 2.2: Auth repository
5. [ ] Phase 2.3: Auth provider

### Sprint 2: Invites
6. [ ] Phase 3.1: Invite models
7. [ ] Phase 3.2: Invite repository
8. [ ] Phase 3.3: Invite provider
9. [ ] Phase 6.4: Invite screens (create + scan)

### Sprint 3: Messaging
10. [ ] Phase 4.1: Session/message models
11. [ ] Phase 4.2: Message storage (SQLite)
12. [ ] Phase 4.3: Chat repository
13. [ ] Phase 4.4: Chat/session providers

### Sprint 4: Nostr & Real-time
14. [ ] Phase 5.1: Nostr service
15. [ ] Phase 5.2: Message subscription
16. [ ] Wire up real Nostr relay connections

### Sprint 5: UI
17. [ ] Phase 6.1: Login screen
18. [ ] Phase 6.2: Chat list screen
19. [ ] Phase 6.3: Chat screen
20. [ ] Polish and animations

### Sprint 6: Integration
21. [ ] Phase 7.1: Full flow integration tests
22. [ ] E2E testing on real devices
23. [ ] Performance optimization
24. [ ] Release preparation

---

## File Structure

```
lib/
├── main.dart
├── config/
│   ├── router.dart
│   ├── theme.dart
│   └── providers/
│       ├── auth_provider.dart
│       ├── chat_provider.dart
│       ├── session_provider.dart
│       └── invite_provider.dart
├── core/
│   ├── ffi/
│   │   ├── ndr_ffi.dart
│   │   └── models/
│   │       ├── keypair.dart
│   │       ├── invite_handle.dart
│   │       └── session_handle.dart
│   ├── services/
│   │   ├── secure_storage_service.dart
│   │   ├── nostr_service.dart
│   │   └── relay_pool.dart
│   └── utils/
│       └── hex_utils.dart
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── identity.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── identity_storage.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── login_screen.dart
│   │       └── widgets/
│   │           └── key_input_field.dart
│   ├── chat/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── session.dart
│   │   │   │   └── message.dart
│   │   │   └── repositories/
│   │   │       └── chat_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── message_local_datasource.dart
│   │   │   │   ├── session_local_datasource.dart
│   │   │   │   └── message_subscription.dart
│   │   │   └── repositories/
│   │   │       └── chat_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── chat_screen.dart
│   │       │   └── chat_list_screen.dart
│   │       └── widgets/
│   │           ├── message_bubble.dart
│   │           ├── message_input.dart
│   │           └── chat_list_item.dart
│   ├── invite/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── invite.dart
│   │   │   └── repositories/
│   │   │       └── invite_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── invite_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── invite_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── create_invite_screen.dart
│   │       │   └── scan_invite_screen.dart
│   │       └── widgets/
│   │           └── qr_code_display.dart
│   └── settings/
│       └── presentation/
│           └── screens/
│               └── settings_screen.dart
└── shared/
    └── widgets/
        ├── loading_indicator.dart
        └── error_display.dart

test/
├── unit/
│   ├── core/
│   │   ├── ffi/
│   │   │   └── ndr_ffi_test.dart
│   │   └── services/
│   │       ├── secure_storage_service_test.dart
│   │       └── nostr_service_test.dart
│   ├── config/
│   │   └── providers/
│   │       ├── auth_provider_test.dart
│   │       ├── chat_provider_test.dart
│   │       └── invite_provider_test.dart
│   └── features/
│       ├── auth/
│       │   └── data/repositories/
│       │       └── auth_repository_test.dart
│       ├── chat/
│       │   ├── domain/models/
│       │   │   ├── session_test.dart
│       │   │   └── message_test.dart
│       │   └── data/
│       │       ├── datasources/
│       │       │   └── message_local_datasource_test.dart
│       │       └── repositories/
│       │           └── chat_repository_test.dart
│       └── invite/
│           ├── domain/models/
│           │   └── invite_test.dart
│           └── data/repositories/
│               └── invite_repository_test.dart
├── widget/
│   └── features/
│       ├── auth/presentation/screens/
│       │   └── login_screen_test.dart
│       ├── chat/presentation/screens/
│       │   ├── chat_screen_test.dart
│       │   └── chat_list_screen_test.dart
│       └── invite/presentation/screens/
│           ├── create_invite_screen_test.dart
│           └── scan_invite_screen_test.dart
└── integration/
    ├── ffi_integration_test.dart
    └── full_chat_flow_test.dart
```

---

## Dependencies on ndr-ffi

The app depends on ndr-ffi bindings. Before starting development:

1. **Build ndr-ffi for mobile**:
   ```bash
   # iOS (macOS only)
   cd nostr-double-ratchet
   ./scripts/mobile/build-ios.sh --release

   # Android
   ./scripts/mobile/build-android.sh --release
   ```

2. **Integrate into Flutter**:
   - iOS: Add `NdrFfi.xcframework` to iOS project
   - Android: Copy `jniLibs/` to `android/app/src/main/`
   - Add Kotlin/Swift bindings to respective native projects

3. **Create Dart wrapper**:
   - Use `flutter_rust_bridge` or manual FFI
   - Wrap all ndr-ffi APIs in Dart-friendly interface

---

## Notes

- All tests written before implementation (TDD)
- Each phase has clear deliverables
- Integration tests validate cross-layer functionality
- Widget tests use `ProviderScope` overrides for mocking
- Real ndr-ffi used in integration tests, mocked in unit tests
