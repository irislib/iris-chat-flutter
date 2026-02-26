import 'dart:async';
import 'dart:convert';

import 'logger_service.dart';
import 'nostr_service.dart';

/// Service for fetching and caching Nostr profiles (kind 0 metadata).
class ProfileService {
  ProfileService(this._nostrService);

  final NostrService _nostrService;
  final Map<String, NostrProfile> _cache = {};
  final Map<String, Completer<NostrProfile?>> _pendingRequests = {};
  final Map<String, Set<String>> _activeSubscriptions = {};
  final Map<String, Timer> _subscriptionTimeouts = {};
  StreamSubscription<NostrEvent>? _eventSubscription;
  final StreamController<String> _profileUpdateController =
      StreamController<String>.broadcast();
  var _subscriptionSequence = 0;

  static const int _metadataKind = 0;
  static const Duration _fetchTimeout = Duration(seconds: 5);

  /// Emits updated pubkeys whenever profile metadata cache changes.
  Stream<String> get profileUpdates => _profileUpdateController.stream;

  /// Get a profile from cache or fetch from relays.
  Future<NostrProfile?> getProfile(String pubkey) async {
    final normalizedPubkey = _normalizePubkey(pubkey);
    if (normalizedPubkey == null) return null;

    // Check cache first
    if (_cache.containsKey(normalizedPubkey)) {
      return _cache[normalizedPubkey];
    }

    // Check if already fetching
    if (_pendingRequests.containsKey(normalizedPubkey)) {
      return _pendingRequests[normalizedPubkey]!.future;
    }

    // Start fetching
    final completer = Completer<NostrProfile?>();
    _pendingRequests[normalizedPubkey] = completer;
    _fetchProfilesInternal([normalizedPubkey]);

    // Timeout after 5 seconds
    return completer.future.timeout(
      _fetchTimeout,
      onTimeout: () {
        if (identical(_pendingRequests[normalizedPubkey], completer)) {
          _pendingRequests.remove(normalizedPubkey);
        }
        return null;
      },
    );
  }

  /// Fetch profiles for multiple pubkeys.
  Future<void> fetchProfiles(List<String> pubkeys) async {
    final toFetch = <String>{};
    for (final pubkey in pubkeys) {
      final normalized = _normalizePubkey(pubkey);
      if (normalized == null || _cache.containsKey(normalized)) {
        continue;
      }
      toFetch.add(normalized);
      _pendingRequests.putIfAbsent(
        normalized,
        Completer<NostrProfile?>.new,
      );
    }
    if (toFetch.isEmpty) return;

    _fetchProfilesInternal(toFetch.toList(growable: false));

    Logger.debug(
      'Fetching profiles',
      category: LogCategory.nostr,
      data: {
        'pubkeyCount': toFetch.length,
        'activeSubs': _activeSubscriptions.length,
      },
    );
  }

  void _fetchProfilesInternal(List<String> pubkeys) {
    if (pubkeys.isEmpty) return;

    _eventSubscription ??= _nostrService.events.listen(_handleEvent);

    final subId =
        'profiles-${DateTime.now().microsecondsSinceEpoch}-${_subscriptionSequence++}';
    _activeSubscriptions[subId] = pubkeys.toSet();
    _subscriptionTimeouts[subId]?.cancel();
    _subscriptionTimeouts[subId] = Timer(_fetchTimeout, () {
      _closeSubscription(subId);
    });

    _nostrService.subscribeWithId(
      subId,
      NostrFilter(
        kinds: const [_metadataKind],
        authors: pubkeys,
        // Allow multiple relays or duplicates to return events; we keep the
        // newest profile per pubkey in cache.
        limit: pubkeys.length * 5,
      ),
    );
  }

  void _handleEvent(NostrEvent event) {
    if (event.kind != _metadataKind) return;

    try {
      final normalizedPubkey = _normalizePubkey(event.pubkey);
      if (normalizedPubkey == null) return;

      final decoded = jsonDecode(event.content);
      if (decoded is! Map) return;
      final metadata = Map<String, dynamic>.from(decoded);
      final profile = NostrProfile(
        pubkey: normalizedPubkey,
        name: metadata['name'] as String?,
        displayName: metadata['display_name'] as String?,
        picture: metadata['picture'] as String?,
        about: metadata['about'] as String?,
        nip05: metadata['nip05'] as String?,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      );

      // Update cache (keep most recent)
      final existing = _cache[normalizedPubkey];
      if (existing == null || profile.updatedAt.isAfter(existing.updatedAt)) {
        _cache[normalizedPubkey] = profile;
        _profileUpdateController.add(normalizedPubkey);
      }

      // Complete pending request
      final completer = _pendingRequests.remove(normalizedPubkey);
      if (completer != null && !completer.isCompleted) {
        completer.complete(_cache[normalizedPubkey]);
      }

      // Resolve subscription lifecycle for this pubkey.
      final subId = event.subscriptionId;
      if (subId != null) {
        final pending = _activeSubscriptions[subId];
        if (pending != null) {
          pending.remove(normalizedPubkey);
          if (pending.isEmpty) {
            _closeSubscription(subId);
          }
        }
      }

      Logger.debug(
        'Profile fetched',
        category: LogCategory.nostr,
        data: {
          'pubkey': normalizedPubkey.substring(0, 8),
          'name': profile.bestName,
        },
      );
    } catch (e) {
      final safePubkey = event.pubkey.length >= 8
          ? event.pubkey.substring(0, 8)
          : event.pubkey;
      Logger.error(
        'Failed to parse profile',
        category: LogCategory.nostr,
        error: e,
        data: {'pubkey': safePubkey},
      );
    }
  }

  /// Get cached profile (synchronous).
  NostrProfile? getCachedProfile(String pubkey) {
    final normalized = _normalizePubkey(pubkey);
    if (normalized == null) return null;
    return _cache[normalized];
  }

  /// Upsert a profile directly into cache (e.g. local profile edits).
  void upsertProfile({
    required String pubkey,
    String? name,
    String? displayName,
    String? picture,
    String? about,
    String? nip05,
    DateTime? updatedAt,
  }) {
    final normalized = _normalizePubkey(pubkey);
    if (normalized == null) return;

    final profile = NostrProfile(
      pubkey: normalized,
      name: name,
      displayName: displayName,
      picture: picture,
      about: about,
      nip05: nip05,
      updatedAt: updatedAt ?? DateTime.now(),
    );

    _cache[normalized] = profile;
    final completer = _pendingRequests.remove(normalized);
    if (completer != null && !completer.isCompleted) {
      completer.complete(profile);
    }
    _profileUpdateController.add(normalized);
  }

  /// Clear the cache.
  void clearCache() => _cache.clear();

  void _closeSubscription(String subId) {
    final unresolvedPubkeys = _activeSubscriptions.remove(subId);
    if (unresolvedPubkeys == null) return;

    _subscriptionTimeouts.remove(subId)?.cancel();
    _nostrService.closeSubscription(subId);

    for (final pubkey in unresolvedPubkeys) {
      if (_cache.containsKey(pubkey)) continue;
      if (_isPubkeyStillRequested(pubkey)) continue;
      final completer = _pendingRequests.remove(pubkey);
      if (completer != null && !completer.isCompleted) {
        completer.complete(null);
      }
    }
  }

  bool _isPubkeyStillRequested(String pubkey) {
    for (final pending in _activeSubscriptions.values) {
      if (pending.contains(pubkey)) return true;
    }
    return false;
  }

  String? _normalizePubkey(String pubkey) {
    final normalized = pubkey.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  /// Dispose of the service.
  Future<void> dispose() async {
    for (final subId in _activeSubscriptions.keys.toList(growable: false)) {
      _closeSubscription(subId);
    }
    for (final timer in _subscriptionTimeouts.values) {
      timer.cancel();
    }
    _subscriptionTimeouts.clear();
    await _eventSubscription?.cancel();
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    await _profileUpdateController.close();
    _activeSubscriptions.clear();
    _cache.clear();
    _pendingRequests.clear();
  }
}

/// Nostr profile from kind 0 metadata.
class NostrProfile {
  const NostrProfile({
    required this.pubkey,
    this.name,
    this.displayName,
    this.picture,
    this.about,
    this.nip05,
    required this.updatedAt,
  });

  final String pubkey;
  final String? name;
  final String? displayName;
  final String? picture;
  final String? about;
  final String? nip05;
  final DateTime updatedAt;

  /// Get the best available name (display_name > name).
  String? get bestName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    return null;
  }
}
