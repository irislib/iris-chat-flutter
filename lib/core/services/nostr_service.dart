import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Service for communicating with Nostr relays.
class NostrService {
  final List<String> _relayUrls;
  final Map<String, WebSocketChannel> _connections = {};
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  final _eventController = StreamController<NostrEvent>.broadcast();

  /// Stream of incoming events from all connected relays.
  Stream<NostrEvent> get events => _eventController.stream;

  /// Default relay URLs.
  static const defaultRelays = [
    'wss://relay.damus.io',
    'wss://relay.snort.social',
    'wss://nos.lol',
    'wss://relay.primal.net',
  ];

  NostrService({List<String>? relayUrls})
      : _relayUrls = relayUrls ?? defaultRelays;

  /// Connect to all configured relays.
  Future<void> connect() async {
    for (final url in _relayUrls) {
      await _connectToRelay(url);
    }
  }

  Future<void> _connectToRelay(String url) async {
    if (_connections.containsKey(url)) return;

    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _connections[url] = channel;

      final subscription = channel.stream.listen(
        (data) => _handleMessage(url, data),
        onError: (error) => _handleError(url, error),
        onDone: () => _handleDisconnect(url),
      );

      _subscriptions[url] = [subscription];
    } catch (e) {
      // Failed to connect, will retry later
    }
  }

  void _handleMessage(String relay, dynamic data) {
    try {
      final message = jsonDecode(data as String) as List;
      final type = message[0] as String;

      switch (type) {
        case 'EVENT':
          final subscriptionId = message[1] as String;
          final eventData = message[2] as Map<String, dynamic>;
          final event = NostrEvent.fromJson(eventData);
          _eventController.add(event);
          break;
        case 'OK':
          // Event was accepted
          break;
        case 'EOSE':
          // End of stored events
          break;
        case 'NOTICE':
          // Relay notice
          break;
      }
    } catch (e) {
      // Invalid message format
    }
  }

  void _handleError(String relay, dynamic error) {
    _connections.remove(relay);
    // Schedule reconnection
    Future.delayed(const Duration(seconds: 5), () => _connectToRelay(relay));
  }

  void _handleDisconnect(String relay) {
    _connections.remove(relay);
    // Schedule reconnection
    Future.delayed(const Duration(seconds: 5), () => _connectToRelay(relay));
  }

  /// Publish an event to all connected relays.
  Future<void> publishEvent(String eventJson) async {
    final message = jsonEncode(['EVENT', jsonDecode(eventJson)]);

    for (final channel in _connections.values) {
      try {
        channel.sink.add(message);
      } catch (e) {
        // Failed to send to this relay
      }
    }
  }

  /// Subscribe to events matching a filter.
  String subscribe(NostrFilter filter) {
    final subscriptionId = _generateSubscriptionId();
    final message = jsonEncode(['REQ', subscriptionId, filter.toJson()]);

    for (final channel in _connections.values) {
      try {
        channel.sink.add(message);
      } catch (e) {
        // Failed to subscribe on this relay
      }
    }

    return subscriptionId;
  }

  /// Close a subscription.
  void closeSubscription(String subscriptionId) {
    final message = jsonEncode(['CLOSE', subscriptionId]);

    for (final channel in _connections.values) {
      try {
        channel.sink.add(message);
      } catch (e) {
        // Failed to close on this relay
      }
    }
  }

  /// Disconnect from all relays.
  Future<void> disconnect() async {
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        await sub.cancel();
      }
    }
    _subscriptions.clear();

    for (final channel in _connections.values) {
      await channel.sink.close();
    }
    _connections.clear();
  }

  String _generateSubscriptionId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }

  /// Get connection status.
  Map<String, bool> get connectionStatus {
    return {
      for (final url in _relayUrls) url: _connections.containsKey(url),
    };
  }

  /// Number of connected relays.
  int get connectedCount => _connections.length;
}

/// A Nostr event.
class NostrEvent {
  final String id;
  final String pubkey;
  final int createdAt;
  final int kind;
  final List<List<String>> tags;
  final String content;
  final String sig;

  const NostrEvent({
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });

  factory NostrEvent.fromJson(Map<String, dynamic> json) {
    return NostrEvent(
      id: json['id'] as String,
      pubkey: json['pubkey'] as String,
      createdAt: json['created_at'] as int,
      kind: json['kind'] as int,
      tags: (json['tags'] as List)
          .map((t) => (t as List).map((e) => e.toString()).toList())
          .toList(),
      content: json['content'] as String,
      sig: json['sig'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pubkey': pubkey,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
      'sig': sig,
    };
  }

  /// Get tag value by name.
  String? getTagValue(String name) {
    for (final tag in tags) {
      if (tag.isNotEmpty && tag[0] == name && tag.length > 1) {
        return tag[1];
      }
    }
    return null;
  }

  /// Get the 'p' tag (recipient pubkey).
  String? get recipientPubkey => getTagValue('p');
}

/// Filter for Nostr subscriptions.
class NostrFilter {
  final List<String>? ids;
  final List<String>? authors;
  final List<int>? kinds;
  final List<String>? eTags;
  final List<String>? pTags;
  final int? since;
  final int? until;
  final int? limit;

  const NostrFilter({
    this.ids,
    this.authors,
    this.kinds,
    this.eTags,
    this.pTags,
    this.since,
    this.until,
    this.limit,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (ids != null) json['ids'] = ids;
    if (authors != null) json['authors'] = authors;
    if (kinds != null) json['kinds'] = kinds;
    if (eTags != null) json['#e'] = eTags;
    if (pTags != null) json['#p'] = pTags;
    if (since != null) json['since'] = since;
    if (until != null) json['until'] = until;
    if (limit != null) json['limit'] = limit;
    return json;
  }
}
