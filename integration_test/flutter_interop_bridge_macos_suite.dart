import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iris_chat/config/providers/auth_provider.dart';
import 'package:iris_chat/config/providers/chat_provider.dart';
import 'package:iris_chat/config/providers/invite_provider.dart';
import 'package:iris_chat/config/providers/nostr_provider.dart';
import 'package:iris_chat/core/services/database_service.dart';
import 'package:iris_chat/core/services/nostr_service.dart';
import 'package:iris_chat/core/services/secure_storage_service.dart';
import 'package:iris_chat/core/services/session_manager_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

SecureStorageService _createInMemorySecureStorage() {
  final store = <String, String?>{};
  final storage = _MockFlutterSecureStorage();

  when(
    () => storage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    final value = invocation.namedArguments[#value] as String?;
    store[key] = value;
  });

  when(() => storage.read(key: any(named: 'key'))).thenAnswer((
    invocation,
  ) async {
    final key = invocation.namedArguments[#key] as String;
    return store[key];
  });

  when(() => storage.containsKey(key: any(named: 'key'))).thenAnswer((
    invocation,
  ) async {
    final key = invocation.namedArguments[#key] as String;
    return store.containsKey(key);
  });

  when(() => storage.delete(key: any(named: 'key'))).thenAnswer((
    invocation,
  ) async {
    final key = invocation.namedArguments[#key] as String;
    store.remove(key);
  });

  Future<void> clearAll(Invocation _) async => store.clear();
  when(storage.deleteAll).thenAnswer(clearAll);

  return SecureStorageService(storage);
}

ProviderContainer _makeContainer({
  required String relayUrl,
  required String dbPath,
  required String ndrPath,
  required SecureStorageService secureStorage,
}) {
  return ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(secureStorage),
      databaseServiceProvider.overrideWithValue(
        DatabaseService(dbPath: dbPath),
      ),
      nostrServiceProvider.overrideWith((ref) {
        final service = NostrService(relayUrls: [relayUrl]);
        ref.onDispose(() {
          unawaited(service.dispose());
        });
        return service;
      }),
      sessionManagerServiceProvider.overrideWith((ref) {
        final nostr = ref.watch(nostrServiceProvider);
        final auth = ref.watch(authRepositoryProvider);

        final svc = SessionManagerService(
          nostr,
          auth,
          storagePathOverride: ndrPath,
        );

        unawaited(svc.start());

        ref.onDispose(() {
          unawaited(svc.dispose());
        });

        return svc;
      }),
    ],
  );
}

Map<String, dynamic> _payloadFor(Map<String, dynamic> command) {
  final payload = command['payload'];
  if (payload is Map<String, dynamic>) return payload;
  if (payload is Map) {
    return Map<String, dynamic>.from(payload);
  }
  return const <String, dynamic>{};
}

Future<void> _emitEvent(File eventsFile, Map<String, dynamic> event) async {
  final line = jsonEncode(event);
  await eventsFile.writeAsString('$line\n', mode: FileMode.append, flush: true);
  // Keep a mirrored stdout breadcrumb for easier local debugging.
  stdout.writeln('IRIS_FLUTTER_INTEROP_EVENT $line');
}

Future<String?> _findSessionIdByRecipient(
  ProviderContainer container,
  String recipientPubkeyHex,
) async {
  final normalized = recipientPubkeyHex.toLowerCase();

  final inMemory = container.read(sessionStateProvider).sessions;
  for (final session in inMemory) {
    if (session.recipientPubkeyHex.toLowerCase() == normalized ||
        session.id.toLowerCase() == normalized) {
      return session.id;
    }
  }

  final fromDb = await container
      .read(sessionDatasourceProvider)
      .getSessionByRecipient(normalized);
  if (fromDb != null) {
    unawaited(
      container.read(sessionStateProvider.notifier).refreshSession(fromDb.id),
    );
    return fromDb.id;
  }

  return null;
}

Future<bool> _waitForMessageText(
  ProviderContainer container, {
  required String text,
  required Duration timeout,
  required bool incomingOnly,
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    final messagesBySession = container.read(chatStateProvider).messages;

    for (final messages in messagesBySession.values) {
      for (final message in messages) {
        if (message.text != text) continue;
        if (incomingOnly && !message.isIncoming) continue;
        return true;
      }
    }

    await Future.delayed(const Duration(milliseconds: 80));
  }

  return false;
}

Future<void> _handleCommand({
  required ProviderContainer container,
  required File eventsFile,
  required Map<String, dynamic> command,
}) async {
  final id = command['id']?.toString() ?? '';
  final type = command['type']?.toString() ?? '';
  final payload = _payloadFor(command);

  Future<void> ok(Map<String, dynamic> data) {
    return _emitEvent(eventsFile, {
      'type': 'response',
      'id': id,
      'ok': true,
      'data': data,
    });
  }

  Future<void> fail(Object error) {
    return _emitEvent(eventsFile, {
      'type': 'response',
      'id': id,
      'ok': false,
      'error': error.toString(),
    });
  }

  try {
    switch (type) {
      case 'get_pubkey':
        final pubkeyHex = container.read(authStateProvider).pubkeyHex;
        if (pubkeyHex == null || pubkeyHex.isEmpty) {
          throw StateError('No authenticated pubkey');
        }
        await ok({'pubkeyHex': pubkeyHex});
        return;

      case 'create_invite':
        final maxUsesRaw = payload['maxUses'];
        final maxUses = maxUsesRaw is num ? maxUsesRaw.toInt() : 1;
        final invite = await container
            .read(inviteStateProvider.notifier)
            .createInvite(maxUses: maxUses);
        if (invite == null) {
          final err = container.read(inviteStateProvider).error;
          throw StateError(err ?? 'Failed to create invite');
        }

        final inviteUrl = await container
            .read(inviteStateProvider.notifier)
            .getInviteUrl(invite.id);
        if (inviteUrl == null || inviteUrl.isEmpty) {
          final err = container.read(inviteStateProvider).error;
          throw StateError(err ?? 'Failed to build invite url');
        }

        await ok({'inviteId': invite.id, 'inviteUrl': inviteUrl});
        return;

      case 'accept_invite':
        final inviteUrl = payload['inviteUrl']?.toString() ?? '';
        if (inviteUrl.isEmpty) {
          throw ArgumentError('accept_invite requires inviteUrl');
        }

        final sessionId = await container
            .read(inviteStateProvider.notifier)
            .acceptInviteFromUrl(inviteUrl);
        if (sessionId == null || sessionId.isEmpty) {
          final err = container.read(inviteStateProvider).error;
          throw StateError(err ?? 'Failed to accept invite');
        }

        await ok({'sessionId': sessionId});
        return;

      case 'wait_for_session':
        final recipientPubkeyHex =
            payload['recipientPubkeyHex']?.toString() ?? '';
        if (recipientPubkeyHex.isEmpty) {
          throw ArgumentError('wait_for_session requires recipientPubkeyHex');
        }

        final timeoutMsRaw = payload['timeoutMs'];
        final timeoutMs = timeoutMsRaw is num ? timeoutMsRaw.toInt() : 30000;
        final end = DateTime.now().add(Duration(milliseconds: timeoutMs));

        while (DateTime.now().isBefore(end)) {
          final sessionId = await _findSessionIdByRecipient(
            container,
            recipientPubkeyHex,
          );
          if (sessionId != null && sessionId.isNotEmpty) {
            await ok({'sessionId': sessionId});
            return;
          }
          await Future.delayed(const Duration(milliseconds: 80));
        }

        throw TimeoutException(
          'Timed out waiting for session',
          Duration(milliseconds: timeoutMs),
        );

      case 'send_message':
        final sessionId = payload['sessionId']?.toString() ?? '';
        final text = payload['text']?.toString() ?? '';
        if (sessionId.isEmpty || text.isEmpty) {
          throw ArgumentError('send_message requires sessionId and text');
        }

        await container
            .read(chatStateProvider.notifier)
            .sendMessage(sessionId, text);
        await ok({});
        return;

      case 'wait_for_message':
        final text = payload['text']?.toString() ?? '';
        if (text.isEmpty) {
          throw ArgumentError('wait_for_message requires text');
        }

        final timeoutMsRaw = payload['timeoutMs'];
        final timeoutMs = timeoutMsRaw is num ? timeoutMsRaw.toInt() : 30000;
        final incomingOnly = payload['incomingOnly'] == true;

        final received = await _waitForMessageText(
          container,
          text: text,
          timeout: Duration(milliseconds: timeoutMs),
          incomingOnly: incomingOnly,
        );

        if (!received) {
          throw TimeoutException(
            'Timed out waiting for message text',
            Duration(milliseconds: timeoutMs),
          );
        }

        await ok({'text': text});
        return;

      case 'shutdown':
        await ok({});
        throw const _ShutdownSignal();

      default:
        throw ArgumentError('Unknown command type: $type');
    }
  } on _ShutdownSignal {
    rethrow;
  } catch (e) {
    await fail(e);
  }
}

Future<void> _runBridgeLoop({
  required ProviderContainer container,
  required File commandsFile,
  required File eventsFile,
}) async {
  var offset = 0;

  while (true) {
    final content = await commandsFile.readAsString();
    if (content.length > offset) {
      final chunk = content.substring(offset);
      offset = content.length;
      final lines = const LineSplitter().convert(chunk);

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        Map<String, dynamic> command;
        try {
          command = jsonDecode(trimmed) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        try {
          await _handleCommand(
            container: container,
            eventsFile: eventsFile,
            command: command,
          );
        } on _ShutdownSignal {
          return;
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 50));
  }
}

class _ShutdownSignal implements Exception {
  const _ShutdownSignal();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flutter interop bridge', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    if (!Platform.isMacOS) {
      return;
    }

    const relayUrl = String.fromEnvironment('IRIS_INTEROP_RELAY_URL');
    const bridgeDirPath = String.fromEnvironment('IRIS_INTEROP_BRIDGE_DIR');
    const privateKeyNsec = String.fromEnvironment(
      'IRIS_INTEROP_PRIVATE_KEY_NSEC',
    );

    expect(relayUrl, isNotEmpty, reason: 'IRIS_INTEROP_RELAY_URL is required');
    expect(
      bridgeDirPath,
      isNotEmpty,
      reason: 'IRIS_INTEROP_BRIDGE_DIR is required',
    );

    final bridgeDir = Directory(bridgeDirPath);
    await bridgeDir.create(recursive: true);

    final commandsFile = File('${bridgeDir.path}/commands.jsonl');
    final eventsFile = File('${bridgeDir.path}/events.jsonl');

    await commandsFile.create(recursive: true);
    await eventsFile.writeAsString('', flush: true);

    final rootDir = await Directory.systemTemp.createTemp('iris-chat-interop-');
    final secureStorage = _createInMemorySecureStorage();

    final container = _makeContainer(
      relayUrl: relayUrl,
      dbPath: '${rootDir.path}/db.sqlite',
      ndrPath: '${rootDir.path}/ndr',
      secureStorage: secureStorage,
    );

    try {
      if (privateKeyNsec.trim().isNotEmpty) {
        await container.read(authStateProvider.notifier).login(privateKeyNsec);
      } else {
        await container.read(authStateProvider.notifier).createIdentity();
      }

      final authState = container.read(authStateProvider);
      expect(
        authState.isAuthenticated,
        isTrue,
        reason: authState.error ?? 'Bridge auth failed',
      );
      await container.read(nostrServiceProvider).connect();

      // Start invite/message bridge wiring.
      container.read(messageSubscriptionProvider);

      await container.read(sessionStateProvider.notifier).loadSessions();
      await container.read(inviteStateProvider.notifier).loadInvites();

      final pubkeyHex = container.read(authStateProvider).pubkeyHex;
      await _emitEvent(eventsFile, {
        'type': 'ready',
        'data': {'pubkeyHex': pubkeyHex, 'relayUrl': relayUrl},
      });

      await _runBridgeLoop(
        container: container,
        commandsFile: commandsFile,
        eventsFile: eventsFile,
      );
    } finally {
      try {
        await container.read(sessionManagerServiceProvider).dispose();
      } catch (_) {}
      try {
        await container.read(nostrServiceProvider).dispose();
      } catch (_) {}
      try {
        await container.read(databaseServiceProvider).close();
      } catch (_) {}
      container.dispose();

      try {
        await rootDir.delete(recursive: true);
      } catch (_) {}
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
