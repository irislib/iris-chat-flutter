import 'package:shared_preferences/shared_preferences.dart';

import 'nostr_service.dart';

/// Snapshot of configured Nostr relay URLs.
class NostrRelaySettingsSnapshot {
  const NostrRelaySettingsSnapshot({required this.relayUrls});

  final List<String> relayUrls;
}

/// Service contract for reading/updating persisted Nostr relay settings.
abstract class NostrRelaySettingsService {
  Future<NostrRelaySettingsSnapshot> load();
  Future<NostrRelaySettingsSnapshot> addRelay(String relayUrl);
  Future<NostrRelaySettingsSnapshot> updateRelay(
    String oldRelayUrl,
    String newRelayUrl,
  );
  Future<NostrRelaySettingsSnapshot> removeRelay(String relayUrl);
}

/// Validate + normalize relay URL input.
///
/// Accepts `ws://` and `wss://` absolute URLs.
String normalizeNostrRelayUrl(String rawUrl) {
  final candidate = rawUrl.trim();
  if (candidate.isEmpty) {
    throw const FormatException('Relay URL is required');
  }

  final uri = Uri.tryParse(candidate);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException(
      'Relay URL must be an absolute ws:// or wss:// URL',
    );
  }

  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'ws' && scheme != 'wss') {
    throw const FormatException('Relay URL must use ws:// or wss://');
  }

  final normalizedUri = uri.replace(
    scheme: scheme,
    host: uri.host.toLowerCase(),
  );
  var normalized = normalizedUri.toString();

  // Normalize trailing slash for root relay URLs.
  if (normalized.endsWith('/') &&
      normalizedUri.path == '/' &&
      !normalizedUri.hasQuery &&
      !normalizedUri.hasFragment) {
    normalized = normalized.substring(0, normalized.length - 1);
  }

  return normalized;
}

class NostrRelaySettingsServiceImpl implements NostrRelaySettingsService {
  NostrRelaySettingsServiceImpl({
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance;

  static const relayUrlsKey = 'settings.nostr_relay_urls';

  final Future<SharedPreferences> Function() _preferencesFactory;

  @override
  Future<NostrRelaySettingsSnapshot> load() async {
    final prefs = await _preferencesFactory();
    final stored = prefs.getStringList(relayUrlsKey);
    final normalized = _normalizeRelayUrls(stored ?? const <String>[]);

    final relayUrls = normalized.isNotEmpty
        ? normalized
        : List<String>.from(NostrService.defaultRelays);

    if (stored == null || !_listsEqual(stored, relayUrls)) {
      await prefs.setStringList(relayUrlsKey, relayUrls);
    }

    return NostrRelaySettingsSnapshot(
      relayUrls: List<String>.unmodifiable(relayUrls),
    );
  }

  @override
  Future<NostrRelaySettingsSnapshot> addRelay(String relayUrl) async {
    final current = (await load()).relayUrls;
    final normalized = normalizeNostrRelayUrl(relayUrl);

    if (current.contains(normalized)) {
      throw StateError('Relay already exists');
    }

    return _save(<String>[...current, normalized]);
  }

  @override
  Future<NostrRelaySettingsSnapshot> updateRelay(
    String oldRelayUrl,
    String newRelayUrl,
  ) async {
    final current = (await load()).relayUrls;
    final oldNormalized = normalizeNostrRelayUrl(oldRelayUrl);
    final newNormalized = normalizeNostrRelayUrl(newRelayUrl);

    final index = current.indexOf(oldNormalized);
    if (index < 0) {
      throw StateError('Relay not found');
    }

    if (oldNormalized != newNormalized && current.contains(newNormalized)) {
      throw StateError('Relay already exists');
    }

    final next = <String>[...current];
    next[index] = newNormalized;
    return _save(next);
  }

  @override
  Future<NostrRelaySettingsSnapshot> removeRelay(String relayUrl) async {
    final current = (await load()).relayUrls;
    final normalized = normalizeNostrRelayUrl(relayUrl);

    final index = current.indexOf(normalized);
    if (index < 0) {
      throw StateError('Relay not found');
    }
    if (current.length == 1) {
      throw StateError('At least one relay is required');
    }

    final next = <String>[...current]..removeAt(index);
    return _save(next);
  }

  Future<NostrRelaySettingsSnapshot> _save(List<String> relayUrls) async {
    final normalized = _normalizeRelayUrls(relayUrls);
    if (normalized.isEmpty) {
      throw StateError('At least one relay is required');
    }

    final prefs = await _preferencesFactory();
    await prefs.setStringList(relayUrlsKey, normalized);

    return NostrRelaySettingsSnapshot(
      relayUrls: List<String>.unmodifiable(normalized),
    );
  }

  List<String> _normalizeRelayUrls(List<String> relayUrls) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final relayUrl in relayUrls) {
      try {
        final relay = normalizeNostrRelayUrl(relayUrl);
        if (seen.add(relay)) {
          normalized.add(relay);
        }
      } catch (_) {
        // Drop invalid values from persisted settings.
      }
    }

    return normalized;
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}
