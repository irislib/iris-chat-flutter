import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/services/database_service.dart';
import '../../features/chat/data/datasources/message_local_datasource.dart';
import '../../features/chat/data/datasources/session_local_datasource.dart';
import '../../features/chat/domain/models/message.dart';
import '../../features/chat/domain/models/session.dart';

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

  ChatNotifier(this._messageDatasource, this._sessionDatasource)
      : super(const ChatState());

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

final sessionStateProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final datasource = ref.watch(sessionDatasourceProvider);
  return SessionNotifier(datasource);
});

final chatStateProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final messageDatasource = ref.watch(messageDatasourceProvider);
  final sessionDatasource = ref.watch(sessionDatasourceProvider);
  return ChatNotifier(messageDatasource, sessionDatasource);
});

/// Provider for messages in a specific session.
final sessionMessagesProvider =
    Provider.family<List<ChatMessage>, String>((ref, sessionId) {
  final chatState = ref.watch(chatStateProvider);
  return chatState.messages[sessionId] ?? [];
});
