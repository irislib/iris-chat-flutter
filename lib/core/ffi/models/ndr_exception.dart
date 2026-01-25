/// Exception types for ndr-ffi operations.
///
/// These map to the NdrError enum in the Rust code.
class NdrException implements Exception {
  final NdrErrorType type;
  final String message;

  const NdrException(this.type, this.message);

  factory NdrException.invalidKey(String message) =>
      NdrException(NdrErrorType.invalidKey, message);

  factory NdrException.invalidEvent(String message) =>
      NdrException(NdrErrorType.invalidEvent, message);

  factory NdrException.cryptoFailure(String message) =>
      NdrException(NdrErrorType.cryptoFailure, message);

  factory NdrException.stateMismatch(String message) =>
      NdrException(NdrErrorType.stateMismatch, message);

  factory NdrException.serialization(String message) =>
      NdrException(NdrErrorType.serialization, message);

  factory NdrException.inviteError(String message) =>
      NdrException(NdrErrorType.inviteError, message);

  factory NdrException.sessionNotReady(String message) =>
      NdrException(NdrErrorType.sessionNotReady, message);

  /// Parse from platform channel error.
  factory NdrException.fromPlatformException(PlatformException e) {
    final code = e.code;
    final message = e.message ?? 'Unknown error';

    switch (code) {
      case 'InvalidKey':
        return NdrException.invalidKey(message);
      case 'InvalidEvent':
        return NdrException.invalidEvent(message);
      case 'CryptoFailure':
        return NdrException.cryptoFailure(message);
      case 'StateMismatch':
        return NdrException.stateMismatch(message);
      case 'Serialization':
        return NdrException.serialization(message);
      case 'InviteError':
        return NdrException.inviteError(message);
      case 'SessionNotReady':
        return NdrException.sessionNotReady(message);
      default:
        return NdrException(NdrErrorType.unknown, message);
    }
  }

  @override
  String toString() => 'NdrException(${type.name}): $message';
}

/// Error types matching the Rust NdrError enum.
enum NdrErrorType {
  invalidKey,
  invalidEvent,
  cryptoFailure,
  stateMismatch,
  serialization,
  inviteError,
  sessionNotReady,
  unknown,
}

// Re-export for convenience
class PlatformException implements Exception {
  final String code;
  final String? message;
  final dynamic details;

  PlatformException({
    required this.code,
    this.message,
    this.details,
  });
}
