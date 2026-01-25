import 'package:flutter_test/flutter_test.dart';

// TODO: Import ndr_ffi when implemented
// import 'package:iris_chat/core/ffi/ndr_ffi.dart';

void main() {
  group('NdrFfi', () {
    group('generateKeypair', () {
      test('returns valid 64-char hex public key', () {
        // TODO: Implement when FFI bindings ready
        // final keypair = NdrFfi.generateKeypair();
        // expect(keypair.publicKeyHex.length, 64);
        // expect(RegExp(r'^[0-9a-f]+$').hasMatch(keypair.publicKeyHex), true);
      });

      test('returns valid 64-char hex private key', () {
        // TODO: Implement when FFI bindings ready
        // final keypair = NdrFfi.generateKeypair();
        // expect(keypair.privateKeyHex.length, 64);
        // expect(RegExp(r'^[0-9a-f]+$').hasMatch(keypair.privateKeyHex), true);
      });

      test('generates unique keypairs each call', () {
        // TODO: Implement when FFI bindings ready
        // final keypair1 = NdrFfi.generateKeypair();
        // final keypair2 = NdrFfi.generateKeypair();
        // expect(keypair1.publicKeyHex, isNot(keypair2.publicKeyHex));
      });
    });

    group('InviteHandle', () {
      test('createNew returns valid invite', () {
        // TODO: Implement when FFI bindings ready
        // final keypair = NdrFfi.generateKeypair();
        // final invite = InviteHandle.createNew(
        //   pubkeyHex: keypair.publicKeyHex,
        // );
        // expect(invite, isNotNull);
      });

      test('toUrl generates valid invite URL', () {
        // TODO: Implement when FFI bindings ready
        // final invite = InviteHandle.createNew(pubkeyHex: testPubkey);
        // final url = invite.toUrl('https://iris.to');
        // expect(url, startsWith('https://iris.to/invite/'));
      });

      test('fromUrl parses valid invite URL', () {
        // TODO: Implement when FFI bindings ready
        // final original = InviteHandle.createNew(pubkeyHex: testPubkey);
        // final url = original.toUrl('https://iris.to');
        // final parsed = InviteHandle.fromUrl(url);
        // expect(parsed, isNotNull);
      });

      test('serialize/deserialize roundtrip preserves data', () {
        // TODO: Implement when FFI bindings ready
        // final invite = InviteHandle.createNew(pubkeyHex: testPubkey);
        // final json = invite.serialize();
        // final restored = InviteHandle.deserialize(json);
        // expect(restored.inviterPubkeyHex, invite.inviterPubkeyHex);
      });

      test('accept creates session and response event', () {
        // TODO: Implement when FFI bindings ready
        // final aliceKeypair = NdrFfi.generateKeypair();
        // final invite = InviteHandle.createNew(pubkeyHex: aliceKeypair.publicKeyHex);
        //
        // final bobKeypair = NdrFfi.generateKeypair();
        // final result = invite.accept(
        //   bobKeypair.publicKeyHex,
        //   bobKeypair.privateKeyHex,
        // );
        //
        // expect(result.session, isNotNull);
        // expect(result.responseEventJson, isNotEmpty);
      });
    });

    group('SessionHandle', () {
      test('canSend returns true when ready', () {
        // TODO: Implement when FFI bindings ready
        // final session = createTestSession();
        // expect(session.canSend(), true);
      });

      test('sendText returns encrypted event', () {
        // TODO: Implement when FFI bindings ready
        // final session = createTestSession();
        // final result = session.sendText('Hello!');
        // expect(result.outerEventJson, isNotEmpty);
        // expect(result.innerEventJson, isNotEmpty);
      });

      test('decryptEvent returns plaintext', () {
        // TODO: Implement when FFI bindings ready
        // final (aliceSession, bobSession) = createTestSessionPair();
        // final sendResult = aliceSession.sendText('Hello Bob!');
        // final decryptResult = bobSession.decryptEvent(sendResult.outerEventJson);
        // expect(decryptResult.plaintext, 'Hello Bob!');
      });

      test('stateJson serializes session state', () {
        // TODO: Implement when FFI bindings ready
        // final session = createTestSession();
        // final state = session.stateJson();
        // expect(state, isNotEmpty);
        // expect(() => jsonDecode(state), returnsNormally);
      });

      test('fromStateJson restores session', () {
        // TODO: Implement when FFI bindings ready
        // final session = createTestSession();
        // final state = session.stateJson();
        // final restored = SessionHandle.fromStateJson(state);
        // expect(restored.canSend(), session.canSend());
      });

      test('isDrMessage identifies double ratchet messages', () {
        // TODO: Implement when FFI bindings ready
        // final session = createTestSession();
        // final result = session.sendText('Test');
        // expect(session.isDrMessage(result.outerEventJson), true);
        // expect(session.isDrMessage('{"kind":1}'), false);
      });
    });

    group('Error handling', () {
      test('invalid key format throws NdrError.InvalidKey', () {
        // TODO: Implement when FFI bindings ready
        // expect(
        //   () => InviteHandle.createNew(pubkeyHex: 'invalid'),
        //   throwsA(isA<NdrError>()),
        // );
      });

      test('invalid event format throws NdrError.InvalidEvent', () {
        // TODO: Implement when FFI bindings ready
        // final session = createTestSession();
        // expect(
        //   () => session.decryptEvent('invalid json'),
        //   throwsA(isA<NdrError>()),
        // );
      });

      test('session not ready throws NdrError.SessionNotReady', () {
        // TODO: Implement when FFI bindings ready
        // Create session that hasn't completed handshake
      });
    });
  });
}

// Helper to create test session pair
// (SessionHandle, SessionHandle) createTestSessionPair() {
//   final alice = NdrFfi.generateKeypair();
//   final bob = NdrFfi.generateKeypair();
//
//   final invite = InviteHandle.createNew(pubkeyHex: alice.publicKeyHex);
//   final acceptResult = invite.accept(bob.publicKeyHex, bob.privateKeyHex);
//
//   // Simulate Alice receiving accept event and creating her session
//   // ...
//
//   return (aliceSession, acceptResult.session);
// }
