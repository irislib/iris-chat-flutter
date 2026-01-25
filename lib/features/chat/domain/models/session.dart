import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

/// Represents an encrypted chat session with another user.
@freezed
class ChatSession with _$ChatSession {
  const ChatSession._();

  const factory ChatSession({
    /// Unique identifier for this session.
    required String id,

    /// The recipient's Nostr public key as hex.
    required String recipientPubkeyHex,

    /// Optional display name for the recipient.
    String? recipientName,

    /// When the session was created.
    required DateTime createdAt,

    /// When the last message was sent/received.
    DateTime? lastMessageAt,

    /// Preview of the last message.
    String? lastMessagePreview,

    /// Number of unread messages.
    @Default(0) int unreadCount,

    /// The invite ID that created this session (if any).
    String? inviteId,

    /// Whether we initiated this session.
    @Default(false) bool isInitiator,

    /// Serialized session state for persistence.
    String? serializedState,
  }) = _ChatSession;

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);

  /// Get a display name for the recipient.
  String get displayName =>
      recipientName ?? _formatPubkey(recipientPubkeyHex);

  static String _formatPubkey(String hex) {
    if (hex.length < 12) return hex;
    return '${hex.substring(0, 6)}...${hex.substring(hex.length - 6)}';
  }
}

/// Session state for UI purposes.
enum SessionStatus {
  /// Session is active and can send/receive.
  active,

  /// Session is pending (waiting for response).
  pending,

  /// Session has an error.
  error,
}
