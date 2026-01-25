import '../models/message.dart';
import '../models/session.dart';

/// Repository for chat sessions and messages.
abstract class ChatRepository {
  // Session operations

  /// Get all chat sessions.
  Future<List<ChatSession>> getSessions();

  /// Get a session by ID.
  Future<ChatSession?> getSession(String id);

  /// Save a session.
  Future<void> saveSession(ChatSession session);

  /// Delete a session and all its messages.
  Future<void> deleteSession(String id);

  /// Update session metadata (last message, unread count, etc.).
  Future<void> updateSessionMetadata(
    String id, {
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    int? unreadCount,
  });

  // Message operations

  /// Get messages for a session.
  Future<List<ChatMessage>> getMessages(
    String sessionId, {
    int? limit,
    String? beforeId,
  });

  /// Send a message.
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String text,
    String? replyToId,
  });

  /// Receive and decrypt a message.
  Future<ChatMessage> receiveMessage({
    required String sessionId,
    required String eventJson,
  });

  /// Update message status.
  Future<void> updateMessageStatus(String messageId, MessageStatus status);

  /// Delete a message.
  Future<void> deleteMessage(String messageId);

  /// Mark all messages in a session as read.
  Future<void> markSessionAsRead(String sessionId);

  // Session state operations

  /// Get the serialized state for a session (for the FFI handle).
  Future<String?> getSessionState(String sessionId);

  /// Save the serialized state for a session.
  Future<void> saveSessionState(String sessionId, String state);
}
