import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/hashtree_attachment_service.dart';
import 'package:iris_chat/core/utils/hashtree_attachments.dart';
import 'package:iris_chat/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeHashtreeAttachmentFfi implements HashtreeAttachmentFfi {
  _FakeHashtreeAttachmentFfi({
    required this.nhash,
    required this.downloadBytesPayload,
  });

  final String nhash;
  Uint8List downloadBytesPayload;
  String? lastNhashFromFilePath;
  final List<Map<String, Object?>> uploadCalls = [];
  final List<Map<String, Object?>> downloadToFileCalls = [];

  @override
  Future<String> nhashFromFile(String filePath) async {
    lastNhashFromFilePath = filePath;
    return nhash;
  }

  @override
  Future<String> uploadFile({
    required String privkeyHex,
    required String filePath,
    required List<String> readServers,
    required List<String> writeServers,
  }) async {
    uploadCalls.add({
      'privkeyHex': privkeyHex,
      'filePath': filePath,
      'readServers': readServers,
      'writeServers': writeServers,
    });
    return nhash;
  }

  @override
  Future<Uint8List> downloadBytes({
    required String nhash,
    required List<String> readServers,
  }) async {
    return Uint8List.fromList(downloadBytesPayload);
  }

  @override
  Future<void> downloadToFile({
    required String nhash,
    required String outputPath,
    required List<String> readServers,
  }) async {
    downloadToFileCalls.add({
      'nhash': nhash,
      'outputPath': outputPath,
      'readServers': readServers,
    });
    final out = File(outputPath);
    await out.parent.create(recursive: true);
    await out.writeAsBytes(downloadBytesPayload, flush: true);
  }
}

void main() {
  const privateKeyHex =
      '1111111111111111111111111111111111111111111111111111111111111111';

  late _MockAuthRepository authRepository;
  late String nhash;
  late _FakeHashtreeAttachmentFfi fakeFfi;

  setUp(() {
    authRepository = _MockAuthRepository();
    when(
      () => authRepository.getPrivateKey(),
    ).thenAnswer((_) async => privateKeyHex);

    nhash =
        'nhash1qqs0ucry576jgwhwvmudmnfzrrpcgafqdlchzv5tpeann357ewygseq9yzyqk7yepaewftz6g5ky56gcy05r4w22xxutdtslcndkgyxy2ppnj7999sn';
    fakeFfi = _FakeHashtreeAttachmentFfi(
      nhash: nhash,
      downloadBytesPayload: Uint8List.fromList(const [9, 8, 7, 6]),
    );
  });

  test(
    'prepareFile computes nhash via ffi and creates attachment link',
    () async {
      final dir = await Directory.systemTemp.createTemp('iris-chat-prepare-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/photo.png');
      await file.writeAsBytes(const [1, 2, 3], flush: true);

      final service = HashtreeAttachmentService(
        authRepository,
        ffi: fakeFfi,
        readServers: <Uri>[Uri.parse('https://cdn.iris.to')],
        writeServers: <Uri>[Uri.parse('https://upload.iris.to')],
      );

      final prepared = await service.prepareFile(
        filePath: file.path,
        fileName: 'photo.png',
      );

      expect(prepared.nhash, nhash);
      expect(prepared.link, '$nhash/photo.png');
      expect(prepared.filename, 'photo.png');
      expect(prepared.encryptedHashHex.length, 64);
      expect(fakeFfi.lastNhashFromFilePath, file.path);
    },
  );

  test(
    'uploadPreparedAttachment uploads using stored path and auth key',
    () async {
      final dir = await Directory.systemTemp.createTemp('iris-chat-upload-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/song.wav');
      await file.writeAsBytes(const [4, 5, 6], flush: true);

      final service = HashtreeAttachmentService(
        authRepository,
        ffi: fakeFfi,
        readServers: <Uri>[Uri.parse('https://cdn.iris.to')],
        writeServers: <Uri>[Uri.parse('https://upload.iris.to')],
      );
      final prepared = await service.prepareFile(
        filePath: file.path,
        fileName: 'song.wav',
      );

      await service.uploadPreparedAttachment(prepared);

      expect(fakeFfi.uploadCalls, hasLength(1));
      expect(fakeFfi.uploadCalls.single['privkeyHex'], privateKeyHex);
      expect(fakeFfi.uploadCalls.single['filePath'], file.path);
      expect(
        fakeFfi.uploadCalls.single['readServers'],
        containsAll(<String>['https://cdn.iris.to', 'https://upload.iris.to']),
      );
      expect(fakeFfi.uploadCalls.single['writeServers'], <String>[
        'https://upload.iris.to',
      ]);
    },
  );

  test(
    'prepareBytes stores temp file and deletes it after successful upload',
    () async {
      final service = HashtreeAttachmentService(
        authRepository,
        ffi: fakeFfi,
        readServers: <Uri>[Uri.parse('https://cdn.iris.to')],
        writeServers: <Uri>[Uri.parse('https://upload.iris.to')],
      );

      final prepared = await service.prepareBytes(
        bytes: Uint8List.fromList(const [7, 7, 7, 7]),
        fileName: 'note.txt',
      );
      await service.uploadPreparedAttachment(prepared);

      final uploadedFilePath =
          fakeFfi.uploadCalls.single['filePath']! as String;
      expect(File(uploadedFilePath).existsSync(), isFalse);
    },
  );

  test('downloadFile returns bytes from ffi', () async {
    final service = HashtreeAttachmentService(
      authRepository,
      ffi: fakeFfi,
      readServers: <Uri>[Uri.parse('https://cdn.iris.to')],
      writeServers: <Uri>[Uri.parse('https://upload.iris.to')],
    );

    final link = parseHashtreeFileLink('$nhash/file.bin')!;
    final bytes = await service.downloadFile(link: link);

    expect(bytes, Uint8List.fromList(const [9, 8, 7, 6]));
  });

  test('downloadFileToPath delegates to ffi and writes output file', () async {
    final service = HashtreeAttachmentService(
      authRepository,
      ffi: fakeFfi,
      readServers: <Uri>[Uri.parse('https://cdn.iris.to')],
      writeServers: <Uri>[Uri.parse('https://upload.iris.to')],
    );

    final dir = await Directory.systemTemp.createTemp('iris-chat-download-');
    addTearDown(() => dir.delete(recursive: true));
    final outputPath = '${dir.path}/payload.bin';

    final link = parseHashtreeFileLink('$nhash/payload.bin')!;
    await service.downloadFileToPath(link: link, outputPath: outputPath);

    final restored = await File(outputPath).readAsBytes();
    expect(restored, Uint8List.fromList(const [9, 8, 7, 6]));
    expect(fakeFfi.downloadToFileCalls, hasLength(1));
    expect(fakeFfi.downloadToFileCalls.single['nhash'], nhash);
  });
}
