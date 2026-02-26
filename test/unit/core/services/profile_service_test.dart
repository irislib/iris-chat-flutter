import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/nostr_service.dart';
import 'package:iris_chat/core/services/profile_service.dart';
import 'package:mocktail/mocktail.dart';

class MockNostrService extends Mock implements NostrService {}

NostrEvent _metadataEvent(
  String pubkey, {
  String? name,
  String? displayName,
  String? picture,
  int createdAt = 1,
  String? subscriptionId,
}) {
  final metadata = <String, String>{};
  if (name != null) metadata['name'] = name;
  if (displayName != null) metadata['display_name'] = displayName;
  if (picture != null) metadata['picture'] = picture;

  return NostrEvent(
    id: '${pubkey}_$createdAt',
    pubkey: pubkey,
    createdAt: createdAt,
    kind: 0,
    tags: const [],
    content: jsonEncode(metadata),
    sig: 'sig',
    subscriptionId: subscriptionId,
  );
}

void main() {
  late MockNostrService nostrService;
  late ProfileService service;
  late StreamController<NostrEvent> eventController;

  setUpAll(() {
    registerFallbackValue(const NostrFilter(authors: <String>[]));
  });

  setUp(() {
    nostrService = MockNostrService();
    eventController = StreamController<NostrEvent>.broadcast();

    when(() => nostrService.events).thenAnswer((_) => eventController.stream);
    when(() => nostrService.subscribe(any())).thenReturn('profile-bulk-sub');
    when(
      () => nostrService.subscribeWithId(any(), any()),
    ).thenAnswer((invocation) => invocation.positionalArguments[0] as String);
    when(() => nostrService.closeSubscription(any())).thenReturn(null);

    service = ProfileService(nostrService);
  });

  tearDown(() async {
    await service.dispose();
    await eventController.close();
  });

  group('ProfileService', () {
    test(
      'does not cancel bulk subscription when getProfile is called for one pending pubkey',
      () async {
        final alice = List.filled(64, 'a').join();
        final bob = List.filled(64, 'b').join();

        await service.fetchProfiles([alice, bob]);

        final future = service.getProfile(alice);
        eventController.add(
          _metadataEvent(
            alice,
            displayName: 'Alice',
            subscriptionId: 'profile-bulk-sub',
          ),
        );

        final profile = await future;

        expect(profile?.bestName, 'Alice');
        verifyNever(() => nostrService.closeSubscription('profile-bulk-sub'));
      },
    );

    test('emits profileUpdates when relay metadata updates cache', () async {
      final pubkey = List.filled(64, 'c').join();
      final updates = <String>[];
      final sub = service.profileUpdates.listen(updates.add);

      await service.fetchProfiles([pubkey]);
      eventController.add(
        _metadataEvent(
          pubkey,
          name: 'carol',
          displayName: 'Carol',
          picture: 'https://example.com/carol.png',
          createdAt: 123,
          subscriptionId: 'profile-sub',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final cached = service.getCachedProfile(pubkey);
      expect(cached?.bestName, 'Carol');
      expect(cached?.picture, 'https://example.com/carol.png');
      expect(updates, [pubkey]);

      await sub.cancel();
    });

    test('upsertProfile writes cache and notifies listeners', () async {
      final pubkey = List.filled(64, 'd').join();
      final updates = <String>[];
      final sub = service.profileUpdates.listen(updates.add);

      service.upsertProfile(
        pubkey: pubkey,
        displayName: 'Dora',
        picture: 'https://example.com/dora.jpg',
      );
      await Future<void>.delayed(Duration.zero);

      final cached = service.getCachedProfile(pubkey);
      expect(cached, isNotNull);
      expect(cached?.bestName, 'Dora');
      expect(cached?.picture, 'https://example.com/dora.jpg');
      expect(updates, [pubkey]);

      await sub.cancel();
    });
  });
}
