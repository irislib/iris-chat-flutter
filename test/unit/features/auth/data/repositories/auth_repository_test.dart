import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iris_chat/core/services/secure_storage_service.dart';
import 'package:iris_chat/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:iris_chat/features/auth/domain/models/identity.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AuthRepositoryImpl repository;
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockStorage = MockSecureStorageService();
    repository = AuthRepositoryImpl(mockStorage);
  });

  group('AuthRepositoryImpl', () {
    group('getCurrentIdentity', () {
      test('returns identity when public key exists', () async {
        const testPubkey =
            'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
        when(() => mockStorage.getPublicKey())
            .thenAnswer((_) async => testPubkey);

        final result = await repository.getCurrentIdentity();

        expect(result, isNotNull);
        expect(result!.pubkeyHex, testPubkey);
      });

      test('returns null when no public key stored', () async {
        when(() => mockStorage.getPublicKey()).thenAnswer((_) async => null);

        final result = await repository.getCurrentIdentity();

        expect(result, isNull);
      });
    });

    group('hasIdentity', () {
      test('delegates to storage', () async {
        when(() => mockStorage.hasIdentity()).thenAnswer((_) async => true);

        final result = await repository.hasIdentity();

        expect(result, true);
        verify(() => mockStorage.hasIdentity()).called(1);
      });
    });

    group('logout', () {
      test('clears identity from storage', () async {
        when(() => mockStorage.clearIdentity()).thenAnswer((_) async {});

        await repository.logout();

        verify(() => mockStorage.clearIdentity()).called(1);
      });
    });

    group('getPrivateKey', () {
      test('returns stored private key', () async {
        const testPrivkey =
            'f1e2d3c4b5a6f1e2d3c4b5a6f1e2d3c4b5a6f1e2d3c4b5a6f1e2d3c4b5a6f1e2';
        when(() => mockStorage.getPrivateKey())
            .thenAnswer((_) async => testPrivkey);

        final result = await repository.getPrivateKey();

        expect(result, testPrivkey);
      });
    });

    group('login', () {
      test('throws InvalidKeyException for invalid key format - too short',
          () async {
        expect(
          () => repository.login('abc123'),
          throwsA(isA<InvalidKeyException>()),
        );
      });

      test('throws InvalidKeyException for invalid key format - non-hex',
          () async {
        // 64 chars but contains invalid characters
        const invalidKey =
            'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz';
        expect(
          () => repository.login(invalidKey),
          throwsA(isA<InvalidKeyException>()),
        );
      });

      // Note: Full login test requires ndr-ffi integration for pubkey derivation
    });

    // Note: createIdentity test requires ndr-ffi integration
    group('createIdentity', () {
      test('generates keypair and stores both keys', () async {
        // This test will work once ndr-ffi is integrated
        // For now, it's a placeholder that shows expected behavior

        // when(() => NdrFfi.generateKeypair()).thenAnswer((_) async => FfiKeyPair(
        //   publicKeyHex: testPubkey,
        //   privateKeyHex: testPrivkey,
        // ));
        // when(() => mockStorage.savePrivateKey(any())).thenAnswer((_) async {});
        // when(() => mockStorage.savePublicKey(any())).thenAnswer((_) async {});

        // final result = await repository.createIdentity();

        // expect(result.pubkeyHex, testPubkey);
        // verify(() => mockStorage.savePrivateKey(testPrivkey)).called(1);
        // verify(() => mockStorage.savePublicKey(testPubkey)).called(1);
      }, skip: 'Requires ndr-ffi integration');
    });
  });
}
