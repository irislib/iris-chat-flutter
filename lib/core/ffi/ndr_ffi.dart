/// Dart bindings for ndr-ffi (Nostr Double Ratchet FFI)
///
/// This provides a Dart-friendly interface to the Rust ndr-ffi library
/// via platform channels to native code (Kotlin/Swift UniFFI bindings).
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'models/models.dart';

export 'models/models.dart';

/// Main interface to the ndr-ffi library.
///
/// All methods are static and communicate with native code via platform channels.
class NdrFfi {
  static const _channel = MethodChannel('to.iris.chat/ndr_ffi');

  /// Returns the version of the ndr-ffi library.
  static Future<String> version() async {
    final result = await _channel.invokeMethod<String>('version');
    return result ?? 'unknown';
  }

  /// Generate a new Nostr keypair.
  ///
  /// Returns a [FfiKeyPair] with hex-encoded public and private keys.
  static Future<FfiKeyPair> generateKeypair() async {
    final result = await _channel.invokeMethod<Map>('generateKeypair');
    if (result == null) {
      throw NdrException.invalidKey('Failed to generate keypair');
    }
    return FfiKeyPair.fromMap(Map<String, dynamic>.from(result));
  }

  /// Create a new invite.
  ///
  /// [inviterPubkeyHex] - The inviter's public key as 64-char hex string.
  /// [deviceId] - Optional device identifier for multi-device support.
  /// [maxUses] - Optional maximum number of times this invite can be accepted.
  static Future<InviteHandle> createInvite({
    required String inviterPubkeyHex,
    String? deviceId,
    int? maxUses,
  }) async {
    final result = await _channel.invokeMethod<Map>('createInvite', {
      'inviterPubkeyHex': inviterPubkeyHex,
      'deviceId': deviceId,
      'maxUses': maxUses,
    });
    if (result == null) {
      throw NdrException.inviteError('Failed to create invite');
    }
    return InviteHandle._fromMap(Map<String, dynamic>.from(result));
  }

  /// Parse an invite from a URL.
  static Future<InviteHandle> inviteFromUrl(String url) async {
    final result = await _channel.invokeMethod<Map>('inviteFromUrl', {
      'url': url,
    });
    if (result == null) {
      throw NdrException.inviteError('Failed to parse invite URL');
    }
    return InviteHandle._fromMap(Map<String, dynamic>.from(result));
  }

  /// Parse an invite from a Nostr event JSON.
  static Future<InviteHandle> inviteFromEventJson(String eventJson) async {
    final result = await _channel.invokeMethod<Map>('inviteFromEventJson', {
      'eventJson': eventJson,
    });
    if (result == null) {
      throw NdrException.inviteError('Failed to parse invite event');
    }
    return InviteHandle._fromMap(Map<String, dynamic>.from(result));
  }

  /// Deserialize an invite from JSON (for persistence).
  static Future<InviteHandle> inviteDeserialize(String json) async {
    final result = await _channel.invokeMethod<Map>('inviteDeserialize', {
      'json': json,
    });
    if (result == null) {
      throw NdrException.serialization('Failed to deserialize invite');
    }
    return InviteHandle._fromMap(Map<String, dynamic>.from(result));
  }

  /// Restore a session from serialized state JSON.
  static Future<SessionHandle> sessionFromStateJson(String stateJson) async {
    final result = await _channel.invokeMethod<Map>('sessionFromStateJson', {
      'stateJson': stateJson,
    });
    if (result == null) {
      throw NdrException.serialization('Failed to restore session');
    }
    return SessionHandle._fromMap(Map<String, dynamic>.from(result));
  }

  /// Derive a public key from a private key.
  ///
  /// [privkeyHex] - The private key as 64-char hex string.
  /// Returns the public key as 64-char hex string.
  static Future<String> derivePublicKey(String privkeyHex) async {
    final result = await _channel.invokeMethod<String>('derivePublicKey', {
      'privkeyHex': privkeyHex,
    });
    if (result == null) {
      throw NdrException.invalidKey('Failed to derive public key');
    }
    return result;
  }

  /// Initialize a new session directly (advanced use).
  static Future<SessionHandle> sessionInit({
    required String theirEphemeralPubkeyHex,
    required String ourEphemeralPrivkeyHex,
    required bool isInitiator,
    required String sharedSecretHex,
    String? name,
  }) async {
    final result = await _channel.invokeMethod<Map>('sessionInit', {
      'theirEphemeralPubkeyHex': theirEphemeralPubkeyHex,
      'ourEphemeralPrivkeyHex': ourEphemeralPrivkeyHex,
      'isInitiator': isInitiator,
      'sharedSecretHex': sharedSecretHex,
      'name': name,
    });
    if (result == null) {
      throw NdrException.sessionNotReady('Failed to initialize session');
    }
    return SessionHandle._fromMap(Map<String, dynamic>.from(result));
  }
}

/// Handle to an invite in native code.
///
/// This class wraps native operations on an invite object.
class InviteHandle {
  final String _id;

  static const _channel = MethodChannel('to.iris.chat/ndr_ffi');

  InviteHandle._(this._id);

  factory InviteHandle._fromMap(Map<String, dynamic> map) {
    return InviteHandle._(map['id'] as String);
  }

  /// Convert the invite to a shareable URL.
  Future<String> toUrl(String root) async {
    final result = await _channel.invokeMethod<String>('inviteToUrl', {
      'id': _id,
      'root': root,
    });
    if (result == null) {
      throw NdrException.inviteError('Failed to generate URL');
    }
    return result;
  }

  /// Convert the invite to a Nostr event JSON.
  Future<String> toEventJson() async {
    final result = await _channel.invokeMethod<String>('inviteToEventJson', {
      'id': _id,
    });
    if (result == null) {
      throw NdrException.inviteError('Failed to generate event');
    }
    return result;
  }

  /// Serialize the invite to JSON for persistence.
  Future<String> serialize() async {
    final result = await _channel.invokeMethod<String>('inviteSerialize', {
      'id': _id,
    });
    if (result == null) {
      throw NdrException.serialization('Failed to serialize invite');
    }
    return result;
  }

  /// Accept the invite and create a session.
  ///
  /// Returns an [InviteAcceptResult] containing the session and response event.
  Future<InviteAcceptResult> accept({
    required String inviteePubkeyHex,
    required String inviteePrivkeyHex,
    String? deviceId,
  }) async {
    final result = await _channel.invokeMethod<Map>('inviteAccept', {
      'id': _id,
      'inviteePubkeyHex': inviteePubkeyHex,
      'inviteePrivkeyHex': inviteePrivkeyHex,
      'deviceId': deviceId,
    });
    if (result == null) {
      throw NdrException.inviteError('Failed to accept invite');
    }
    return InviteAcceptResult._fromMap(Map<String, dynamic>.from(result));
  }

  /// Get the inviter's public key as hex.
  Future<String> getInviterPubkeyHex() async {
    final result =
        await _channel.invokeMethod<String>('inviteGetInviterPubkeyHex', {
      'id': _id,
    });
    if (result == null) {
      throw NdrException.inviteError('Failed to get inviter pubkey');
    }
    return result;
  }

  /// Get the shared secret as hex.
  Future<String> getSharedSecretHex() async {
    final result =
        await _channel.invokeMethod<String>('inviteGetSharedSecretHex', {
      'id': _id,
    });
    if (result == null) {
      throw NdrException.inviteError('Failed to get shared secret');
    }
    return result;
  }

  /// Dispose of the native invite handle.
  Future<void> dispose() async {
    await _channel.invokeMethod<void>('inviteDispose', {'id': _id});
  }
}

/// Handle to a session in native code.
///
/// This class wraps native operations on a session object.
class SessionHandle {
  final String _id;

  static const _channel = MethodChannel('to.iris.chat/ndr_ffi');

  SessionHandle._(this._id);

  factory SessionHandle._fromMap(Map<String, dynamic> map) {
    return SessionHandle._(map['id'] as String);
  }

  /// Unique identifier for this session handle.
  String get id => _id;

  /// Check if the session is ready to send messages.
  Future<bool> canSend() async {
    final result = await _channel.invokeMethod<bool>('sessionCanSend', {
      'id': _id,
    });
    return result ?? false;
  }

  /// Send a text message.
  ///
  /// Returns a [SendResult] containing the encrypted outer event
  /// and the original inner event.
  Future<SendResult> sendText(String text) async {
    final result = await _channel.invokeMethod<Map>('sessionSendText', {
      'id': _id,
      'text': text,
    });
    if (result == null) {
      throw NdrException.sessionNotReady('Failed to send message');
    }
    return SendResult.fromMap(Map<String, dynamic>.from(result));
  }

  /// Decrypt a received event.
  ///
  /// Returns a [DecryptResult] containing the plaintext and inner event.
  Future<DecryptResult> decryptEvent(String outerEventJson) async {
    final result = await _channel.invokeMethod<Map>('sessionDecryptEvent', {
      'id': _id,
      'outerEventJson': outerEventJson,
    });
    if (result == null) {
      throw NdrException.cryptoFailure('Failed to decrypt event');
    }
    return DecryptResult.fromMap(Map<String, dynamic>.from(result));
  }

  /// Serialize the session state to JSON.
  Future<String> stateJson() async {
    final result = await _channel.invokeMethod<String>('sessionStateJson', {
      'id': _id,
    });
    if (result == null) {
      throw NdrException.serialization('Failed to serialize session');
    }
    return result;
  }

  /// Check if an event is a double-ratchet message.
  Future<bool> isDrMessage(String eventJson) async {
    final result = await _channel.invokeMethod<bool>('sessionIsDrMessage', {
      'id': _id,
      'eventJson': eventJson,
    });
    return result ?? false;
  }

  /// Dispose of the native session handle.
  Future<void> dispose() async {
    await _channel.invokeMethod<void>('sessionDispose', {'id': _id});
  }
}

/// Result of accepting an invite.
class InviteAcceptResult {
  final SessionHandle session;
  final String responseEventJson;

  InviteAcceptResult({
    required this.session,
    required this.responseEventJson,
  });

  factory InviteAcceptResult._fromMap(Map<String, dynamic> map) {
    return InviteAcceptResult(
      session: SessionHandle._fromMap(
        Map<String, dynamic>.from(map['session'] as Map),
      ),
      responseEventJson: map['responseEventJson'] as String,
    );
  }
}
