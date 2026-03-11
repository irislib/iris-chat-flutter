import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/secure_storage_service.dart';
import 'package:iris_chat/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:iris_chat/features/auth/domain/models/identity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nostr/nostr.dart' as nostr;

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRepositoryImpl repository;
  late MockSecureStorageService mockStorage;
  late String testPrivkeyNsec;

  const testPubkey =
      'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
  const testPrivkey =
      'f1e2d3c4b5a6f1e2d3c4b5a6f1e2d3c4b5a6f1e2d3c4b5a6f1e2d3c4b5a6f1e2';
  const generatedDevicePrivkey =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
  const generatedDevicePubkey =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  setUp(() {
    mockStorage = MockSecureStorageService();
    repository = AuthRepositoryImpl(mockStorage);
    testPrivkeyNsec = nostr.Nip19.encodePrivkey(testPrivkey) as String;
  });

  group('AuthRepositoryImpl', () {
    group('getCurrentIdentity', () {
      test('returns identity when public key exists', () async {
        when(
          () => mockStorage.getPublicKey(),
        ).thenAnswer((_) async => testPubkey);

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
      test('clears all secure storage data', () async {
        when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

        await repository.logout();

        verify(() => mockStorage.deleteAll()).called(1);
      });
    });

    group('getPrivateKey', () {
      test('returns stored private key', () async {
        when(
          () => mockStorage.getPrivateKey(),
        ).thenAnswer((_) async => testPrivkey);

        final result = await repository.getPrivateKey();

        expect(result, testPrivkey);
      });
    });

    group('getOwnerPrivateKey', () {
      test('returns stored owner key when available', () async {
        when(
          () => mockStorage.getOwnerPrivateKey(),
        ).thenAnswer((_) async => testPrivkey);

        final result = await repository.getOwnerPrivateKey();

        expect(result, testPrivkey);
      });

      test(
        'infers legacy owner key when stored pubkey matches device key',
        () async {
          when(
            () => mockStorage.getOwnerPrivateKey(),
          ).thenAnswer((_) async => null);
          when(
            () => mockStorage.getPrivateKey(),
          ).thenAnswer((_) async => testPrivkey);
          when(
            () => mockStorage.getPublicKey(),
          ).thenAnswer((_) async => testPubkey);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('to.iris.chat/ndr_ffi'),
                (MethodCall methodCall) async {
                  if (methodCall.method == 'derivePublicKey') {
                    final args = methodCall.arguments as Map<dynamic, dynamic>;
                    final privkeyHex = args['privkeyHex'] as String;
                    if (privkeyHex == testPrivkey) {
                      return testPubkey;
                    }
                  }
                  return null;
                },
              );

          final result = await repository.getOwnerPrivateKey();

          expect(result, testPrivkey);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('to.iris.chat/ndr_ffi'),
                null,
              );
        },
      );
    });

    group('login', () {
      test(
        'throws InvalidKeyException for invalid key format - too short',
        () async {
          expect(
            () => repository.login('abc123'),
            throwsA(isA<InvalidKeyException>()),
          );
        },
      );

      test(
        'throws InvalidKeyException for invalid key format - raw hex',
        () async {
          expect(
            () => repository.login(testPrivkey),
            throwsA(isA<InvalidKeyException>()),
          );
        },
      );

      test(
        'throws InvalidKeyException for invalid key format - malformed nsec',
        () async {
          expect(
            () => repository.login('nsec1notavalidbech32key'),
            throwsA(isA<InvalidKeyException>()),
          );
        },
      );
    });

    group('createIdentity', () {
      test('generates keypair via ndr-ffi and stores both keys', () async {
        // Mock the MethodChannel for ndr-ffi
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('to.iris.chat/ndr_ffi'),
              (MethodCall methodCall) async {
                if (methodCall.method == 'generateKeypair') {
                  return {
                    'publicKeyHex': testPubkey,
                    'privateKeyHex': testPrivkey,
                  };
                }
                return null;
              },
            );

        when(
          () => mockStorage.saveIdentity(
            privkeyHex: any(named: 'privkeyHex'),
            pubkeyHex: any(named: 'pubkeyHex'),
            ownerPrivkeyHex: any(named: 'ownerPrivkeyHex'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.createIdentity();

        expect(result.pubkeyHex, testPubkey);
        verify(
          () => mockStorage.saveIdentity(
            privkeyHex: testPrivkey,
            pubkeyHex: testPubkey,
            ownerPrivkeyHex: testPrivkey,
          ),
        ).called(1);

        // Clean up mock
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('to.iris.chat/ndr_ffi'),
              null,
            );
      });
    });

    group('login with valid key', () {
      test(
        'stores generated device key and keeps owner key separately by default',
        () async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('to.iris.chat/ndr_ffi'),
                (MethodCall methodCall) async {
                  if (methodCall.method == 'generateKeypair') {
                    return {
                      'publicKeyHex': generatedDevicePubkey,
                      'privateKeyHex': generatedDevicePrivkey,
                    };
                  }
                  if (methodCall.method == 'derivePublicKey') {
                    final args = methodCall.arguments as Map<dynamic, dynamic>;
                    final privkeyHex = args['privkeyHex'] as String;
                    if (privkeyHex == testPrivkey) {
                      return testPubkey;
                    }
                    if (privkeyHex == generatedDevicePrivkey) {
                      return generatedDevicePubkey;
                    }
                  }
                  return null;
                },
              );

          when(
            () => mockStorage.saveIdentity(
              privkeyHex: any(named: 'privkeyHex'),
              pubkeyHex: any(named: 'pubkeyHex'),
              ownerPrivkeyHex: any(named: 'ownerPrivkeyHex'),
            ),
          ).thenAnswer((_) async {});

          final result = await repository.login(testPrivkeyNsec);

          expect(result.pubkeyHex, testPubkey);
          verify(
            () => mockStorage.saveIdentity(
              privkeyHex: generatedDevicePrivkey,
              pubkeyHex: testPubkey,
              ownerPrivkeyHex: testPrivkey,
            ),
          ).called(1);

          // Clean up mock
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('to.iris.chat/ndr_ffi'),
                null,
              );
        },
      );

      test('derives public key and stores identity from nsec', () async {
        // Mock the MethodChannel for ndr-ffi
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('to.iris.chat/ndr_ffi'),
              (MethodCall methodCall) async {
                if (methodCall.method == 'derivePublicKey') {
                  final args = methodCall.arguments as Map<dynamic, dynamic>;
                  expect(args['privkeyHex'], testPrivkey);
                  return testPubkey;
                }
                return null;
              },
            );

        when(
          () => mockStorage.saveIdentity(
            privkeyHex: any(named: 'privkeyHex'),
            pubkeyHex: any(named: 'pubkeyHex'),
            ownerPrivkeyHex: any(named: 'ownerPrivkeyHex'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.login(
          testPrivkeyNsec,
          devicePrivkeyHex: testPrivkey,
        );

        expect(result.pubkeyHex, testPubkey);
        verify(
          () => mockStorage.saveIdentity(
            privkeyHex: testPrivkey,
            pubkeyHex: testPubkey,
            ownerPrivkeyHex: testPrivkey,
          ),
        ).called(1);

        // Clean up mock
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('to.iris.chat/ndr_ffi'),
              null,
            );
      });

      test('accepts nostr:nsec uri format', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('to.iris.chat/ndr_ffi'),
              (MethodCall methodCall) async {
                if (methodCall.method == 'derivePublicKey') {
                  final args = methodCall.arguments as Map<dynamic, dynamic>;
                  expect(args['privkeyHex'], testPrivkey);
                  return testPubkey;
                }
                return null;
              },
            );

        when(
          () => mockStorage.saveIdentity(
            privkeyHex: any(named: 'privkeyHex'),
            pubkeyHex: any(named: 'pubkeyHex'),
            ownerPrivkeyHex: any(named: 'ownerPrivkeyHex'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.login(
          'nostr:$testPrivkeyNsec',
          devicePrivkeyHex: testPrivkey,
        );

        expect(result.pubkeyHex, testPubkey);
        verify(
          () => mockStorage.saveIdentity(
            privkeyHex: testPrivkey,
            pubkeyHex: testPubkey,
            ownerPrivkeyHex: testPrivkey,
          ),
        ).called(1);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('to.iris.chat/ndr_ffi'),
              null,
            );
      });
    });
  });
}
