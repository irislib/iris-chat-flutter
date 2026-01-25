import '../models/identity.dart';

/// Repository for authentication and identity management.
abstract class AuthRepository {
  /// Create a new identity with a generated keypair.
  Future<Identity> createIdentity();

  /// Login with an existing private key.
  ///
  /// Throws [InvalidKeyException] if the key is invalid.
  Future<Identity> login(String privkeyHex);

  /// Get the current identity, if any.
  Future<Identity?> getCurrentIdentity();

  /// Check if user has an identity stored.
  Future<bool> hasIdentity();

  /// Logout and clear stored identity.
  Future<void> logout();

  /// Get the stored private key (use with caution).
  Future<String?> getPrivateKey();
}
