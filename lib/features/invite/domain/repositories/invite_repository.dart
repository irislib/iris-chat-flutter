import '../models/invite.dart';

/// Repository for invite management.
abstract class InviteRepository {
  /// Create a new invite.
  Future<Invite> createInvite({String? label, int? maxUses});

  /// Get all stored invites.
  Future<List<Invite>> getAllInvites();

  /// Get active (non-expired, can be used) invites.
  Future<List<Invite>> getActiveInvites();

  /// Get an invite by ID.
  Future<Invite?> getInvite(String id);

  /// Update an invite.
  Future<void> updateInvite(Invite invite);

  /// Delete an invite.
  Future<void> deleteInvite(String id);

  /// Accept an invite from a URL.
  Future<InviteAcceptData> acceptInviteFromUrl(String url);

  /// Accept an invite from a Nostr event JSON.
  Future<InviteAcceptData> acceptInviteFromEvent(String eventJson);

  /// Get the shareable URL for an invite.
  Future<String> getInviteUrl(String id, {String root = 'https://iris.to'});

  /// Get the Nostr event JSON for an invite.
  Future<String> getInviteEventJson(String id);

  /// Mark an invite as used by a pubkey.
  Future<void> markInviteUsed(String id, String acceptedByPubkey);
}
