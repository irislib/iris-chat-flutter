import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/ffi/ndr_ffi.dart';
import '../../core/services/database_service.dart';
import '../../core/services/nostr_service.dart';
import '../../features/chat/data/datasources/message_local_datasource.dart';
import '../../features/chat/data/datasources/session_local_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/models/message.dart';
import '../../features/chat/domain/models/session.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import 'nostr_provider.dart';

part 'chat_provider.freezed.dart';

/// State for chat sessions.
@freezed
class SessionState with _$SessionState {
  const factory SessionState({
    @Default([]) List<ChatSession> sessions,
    @Default(false) bool isLoading,
    String? error,
  }) = _SessionState;
}

/// State for messages in a chat.
@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    @Default({}) Map<String, List<ChatMessage>> messages,
    @Default({}) Map<String, int> unreadCounts,
    @Default({}) Map<String, bool> sendingStates,
    String? error,
  }) = _ChatState;
}

/// Notifier for session state.
class SessionNotifier extends StateNotifier<SessionState> {
  final SessionLocalDatasource _sessionDatasource;

  SessionNotifier(this._sessionDatasource) : super(const SessionState());

  /// Load all sessions from storage.
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sessions = await _sessionDatasource.getAllSessions();
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a new session.
  Future<void> addSession(ChatSession session) async {
    await _sessionDatasource.saveSession(session);
    state = state.copyWith(
      sessions: [session, ...state.sessions],
    );
  }

  /// Update a session.
  Future<void> updateSession(ChatSession session) async {
    await _sessionDatasource.saveSession(session);
    state = state.copyWith(
      sessions: state.sessions
          .map((s) => s.id == session.id ? session : s)
          .toList(),
    );
  }

  /// Delete a session.
  Future<void> deleteSession(String id) async {
    await _sessionDatasource.deleteSession(id);
    state = state.copyWith(
      sessions: state.sessions.where((s) => s.id != id).toList(),
    );
  }

  /// Update session with new message info.
  Future<void> updateSessionWithMessage(
    String sessionId,
    ChatMessage message,
  ) async {
    await _sessionDatasource.updateMetadata(
      sessionId,
      lastMessageAt: message.timestamp,
      lastMessagePreview: message.text.length > 50
          ? '${message.text.substring(0, 50)}...'
          : message.text,
    );

    state = state.copyWith(
      sessions: state.sessions.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(
            lastMessageAt: message.timestamp,
            lastMessagePreview: message.text.length > 50
                ? '${message.text.substring(0, 50)}...'
                : message.text,
          );
        }
        return s;
      }).toList(),
    );
  }

  /// Increment unread count for a session.
  Future<void> incrementUnread(String sessionId) async {
    final session = state.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );

    await _sessionDatasource.updateMetadata(
      sessionId,
      unreadCount: session.unreadCount + 1,
    );

    state = state.copyWith(
      sessions: state.sessions.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(unreadCount: s.unreadCount + 1);
        }
        return s;
      }).toList(),
    );
  }

  /// Clear unread count for a session.
  Future<void> clearUnread(String sessionId) async {
    await _sessionDatasource.updateMetadata(sessionId, unreadCount: 0);

    state = state.copyWith(
      sessions: state.sessions.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(unreadCount: 0);
        }
        return s;
      }).toList(),
    );
  }
}

/// Notifier for chat messages.
class ChatNotifier extends StateNotifier<ChatState> {
  final MessageLocalDatasource _messageDatasource;
  final SessionLocalDatasource _sessionDatasource;
  final NostrService _nostrService;

  // Cache of session handles for sending/receiving
  final Map<String, SessionHandle> _sessionHandles = {};

  ChatNotifier(
    this._messageDatasource,
    this._sessionDatasource,
    this._nostrService,
  ) : super(const ChatState());

  /// Load messages for a session.
  Future<void> loadMessages(String sessionId, {int limit = 50}) async {
    try {
      final messages = await _messageDatasource.getMessagesForSession(
        sessionId,
        limit: limit,
      );
      state = state.copyWith(
        messages: {...state.messages, sessionId: messages},
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load more messages (pagination).
  Future<void> loadMoreMessages(String sessionId, {int limit = 50}) async {
    final currentMessages = state.messages[sessionId] ?? [];
    if (currentMessages.isEmpty) {
      return loadMessages(sessionId, limit: limit);
    }

    try {
      final oldestMessage = currentMessages.first;
      final olderMessages = await _messageDatasource.getMessagesForSession(
        sessionId,
        limit: limit,
        beforeId: oldestMessage.id,
      );

      state = state.copyWith(
        messages: {
          ...state.messages,
          sessionId: [...olderMessages, ...currentMessages],
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add a message optimistically.
  void addMessageOptimistic(ChatMessage message) {
    final sessionId = message.sessionId;
    final currentMessages = state.messages[sessionId] ?? [];

    state = state.copyWith(
      messages: {
        ...state.messages,
        sessionId: [...currentMessages, message],
      },
      sendingStates: {...state.sendingStates, message.id: true},
    );
  }

  /// Send a message.
  Future<void> sendMessage(String sessionId, String text) async {
    // Create optimistic message
    final message = ChatMessage.outgoing(
      sessionId: sessionId,
      text: text,
    );

    // Add to UI immediately
    addMessageOptimistic(message);

    try {
      // Get or restore the session handle
      final handle = await _getSessionHandle(sessionId);
      if (handle == null) {
        throw Exception('Session not found');
      }

      // Check if can send
      final canSend = await handle.canSend();
      if (!canSend) {
        throw Exception('Session is not ready');
      }

      // Encrypt and get event
      final sendResult = await handle.sendText(text);

      // Update session state
      final newState = await handle.stateJson();
      await _sessionDatasource.saveSessionState(sessionId, newState);

      // Publish to Nostr
      await _nostrService.publishEvent(sendResult.outerEventJson);

      // Parse event ID
      final eventData = jsonDecode(sendResult.outerEventJson) as Map<String, dynamic>;
      final eventId = eventData['id'] as String;

      // Update message with success
      final sentMessage = message.copyWith(
        status: MessageStatus.sent,
        eventId: eventId,
      );
      await updateMessage(sentMessage);
    } catch (e) {
      // Update message with failure
      final failedMessage = message.copyWith(status: MessageStatus.failed);
      await updateMessage(failedMessage);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Receive a message from Nostr.
  Future<void> receiveMessage(String sessionId, String eventJson) async {
    try {
      // Check if already have this message
      final eventData = jsonDecode(eventJson) as Map<String, dynamic>;
      final eventId = eventData['id'] as String;

      if (await _messageDatasource.messageExists(eventId)) {
        return; // Already have this message
      }

      // Get or restore the session handle
      final handle = await _getSessionHandle(sessionId);
      if (handle == null) {
        return;
      }

      // Decrypt
      final decryptResult = await handle.decryptEvent(eventJson);

      // Update session state
      final newState = await handle.stateJson();
      await _sessionDatasource.saveSessionState(sessionId, newState);

      // Parse timestamp
      final createdAt = eventData['created_at'] as int;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);

      // Create message
      final message = ChatMessage.incoming(
        sessionId: sessionId,
        text: decryptResult.plaintext,
        eventId: eventId,
        timestamp: timestamp,
      );

      // Save and add to state
      await addReceivedMessage(message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update a message (e.g., after sending succeeds).
  Future<void> updateMessage(ChatMessage message) async {
    await _messageDatasource.saveMessage(message);

    final sessionId = message.sessionId;
    final currentMessages = state.messages[sessionId] ?? [];

    state = state.copyWith(
      messages: {
        ...state.messages,
        sessionId: currentMessages
            .map((m) => m.id == message.id ? message : m)
            .toList(),
      },
      sendingStates: {...state.sendingStates}..remove(message.id),
    );
  }

  /// Add a received message.
  Future<void> addReceivedMessage(ChatMessage message) async {
    // Check if message already exists
    if (message.eventId != null) {
      final exists = await _messageDatasource.messageExists(message.eventId!);
      if (exists) return;
    }

    await _messageDatasource.saveMessage(message);

    final sessionId = message.sessionId;
    final currentMessages = state.messages[sessionId] ?? [];

    state = state.copyWith(
      messages: {
        ...state.messages,
        sessionId: [...currentMessages, message],
      },
    );
  }

  /// Update message status.
  Future<void> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    await _messageDatasource.updateMessageStatus(messageId, status);

    state = state.copyWith(
      messages: state.messages.map((sessionId, messages) {
        return MapEntry(
          sessionId,
          messages.map((m) {
            if (m.id == messageId) {
              return m.copyWith(status: status);
            }
            return m;
          }).toList(),
        );
      }),
    );
  }

  /// Get or restore a session handle.
  Future<SessionHandle?> _getSessionHandle(String sessionId) async {
    if (_sessionHandles.containsKey(sessionId)) {
      return _sessionHandles[sessionId];
    }

    final stateJson = await _sessionDatasource.getSessionState(sessionId);
    if (stateJson == null) return null;

    try {
      final handle = await NdrFfi.sessionFromStateJson(stateJson);
      _sessionHandles[sessionId] = handle;
      return handle;
    } catch (e) {
      return null;
    }
  }

  /// Cache a session handle.
  void cacheSessionHandle(String sessionId, SessionHandle handle) {
    _sessionHandles[sessionId] = handle;
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final sessionDatasourceProvider = Provider<SessionLocalDatasource>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SessionLocalDatasource(db);
});

final messageDatasourceProvider = Provider<MessageLocalDatasource>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return MessageLocalDatasource(db);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final sessionDatasource = ref.watch(sessionDatasourceProvider);
  final messageDatasource = ref.watch(messageDatasourceProvider);
  final nostrService = ref.watch(nostrServiceProvider);

  return ChatRepositoryImpl(
    sessionDatasource: sessionDatasource,
    messageDatasource: messageDatasource,
    nostrService: nostrService,
  );
});

final sessionStateProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final datasource = ref.watch(sessionDatasourceProvider);
  return SessionNotifier(datasource);
});

final chatStateProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final messageDatasource = ref.watch(messageDatasourceProvider);
  final sessionDatasource = ref.watch(sessionDatasourceProvider);
  final nostrService = ref.watch(nostrServiceProvider);
  return ChatNotifier(messageDatasource, sessionDatasource, nostrService);
});

/// Provider for messages in a specific session.
final sessionMessagesProvider =
    Provider.family<List<ChatMessage>, String>((ref, sessionId) {
  final chatState = ref.watch(chatStateProvider);
  return chatState.messages[sessionId] ?? [];
});
