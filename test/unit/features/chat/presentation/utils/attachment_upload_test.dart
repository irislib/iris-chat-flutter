import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/hashtree_attachment_service.dart';
import 'package:iris_chat/features/chat/presentation/utils/attachment_upload.dart';
import 'package:mocktail/mocktail.dart';

class _MockHashtreeAttachmentService extends Mock
    implements HashtreeAttachmentService {}

void main() {
  late _MockHashtreeAttachmentService service;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      HashtreePreparedAttachment(
        nhash: 'nhash1fallback',
        link: 'nhash1fallback/file.png',
        filename: 'file.png',
        encryptedHashHex: 'cafebabe',
        encryptedBytes: Uint8List.fromList(<int>[1]),
      ),
    );
  });

  setUp(() {
    service = _MockHashtreeAttachmentService();
  });

  test(
    'prepare uses file path upload preparation when picker returns a path',
    () async {
      final preparedAttachment = HashtreePreparedAttachment(
        nhash: 'nhash1prep123',
        link: 'nhash1prep123/file.png',
        filename: 'file.png',
        encryptedHashHex: 'beadfeed',
        encryptedBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );
      final picked = PlatformFile(
        name: 'photo.png',
        size: 5,
        path: '/tmp/photo.png',
        bytes: null,
      );

      when(
        () => service.prepareFile(
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
        ),
      ).thenAnswer((_) async => preparedAttachment);

      final prepared = await preparePickedAttachment(
        pickedFile: picked,
        service: service,
      );

      expect(prepared, preparedAttachment);
      verify(
        () => service.prepareFile(
          filePath: '/tmp/photo.png',
          fileName: 'photo.png',
        ),
      ).called(1);
      verifyNever(
        () => service.prepareBytes(
          bytes: any(named: 'bytes'),
          fileName: any(named: 'fileName'),
        ),
      );
    },
  );

  test('prepare falls back to bytes when picker returns no path', () async {
    final preparedAttachment = HashtreePreparedAttachment(
      nhash: 'nhash1prep123',
      link: 'nhash1prep123/file.png',
      filename: 'file.png',
      encryptedHashHex: 'beadfeed',
      encryptedBytes: Uint8List.fromList(<int>[1, 2, 3]),
    );
    final picked = PlatformFile(
      name: 'photo.png',
      size: 3,
      path: null,
      bytes: Uint8List.fromList(const [1, 2, 3]),
    );

    when(
      () => service.prepareBytes(
        bytes: any(named: 'bytes'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => preparedAttachment);

    final prepared = await preparePickedAttachment(
      pickedFile: picked,
      service: service,
    );

    expect(prepared, preparedAttachment);
    verify(
      () => service.prepareBytes(
        bytes: any(named: 'bytes'),
        fileName: 'photo.png',
      ),
    ).called(1);
    verifyNever(
      () => service.prepareFile(
        filePath: any(named: 'filePath'),
        fileName: any(named: 'fileName'),
      ),
    );
  });

  test('uses file path upload when picker returns a path', () async {
    final preparedAttachment = HashtreePreparedAttachment(
      nhash: 'nhash1abc123',
      link: 'nhash1abc123/photo.png',
      filename: 'photo.png',
      encryptedHashHex: 'deadbeef',
      encryptedBytes: Uint8List.fromList(<int>[4, 5, 6]),
    );
    final picked = PlatformFile(
      name: 'photo.png',
      size: 5,
      path: '/tmp/photo.png',
      bytes: null,
    );

    when(
      () => service.prepareFile(
        filePath: any(named: 'filePath'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => preparedAttachment);
    when(
      () => service.uploadPreparedAttachment(any()),
    ).thenAnswer((_) async {});

    final uploaded = await uploadPickedAttachment(
      pickedFile: picked,
      service: service,
    );

    expect(uploaded.nhash, preparedAttachment.nhash);
    expect(uploaded.link, preparedAttachment.link);
    expect(uploaded.filename, preparedAttachment.filename);
    expect(uploaded.encryptedHashHex, preparedAttachment.encryptedHashHex);
    verify(
      () => service.prepareFile(
        filePath: '/tmp/photo.png',
        fileName: 'photo.png',
      ),
    ).called(1);
    verify(
      () => service.uploadPreparedAttachment(preparedAttachment),
    ).called(1);
    verifyNever(
      () => service.prepareBytes(
        bytes: any(named: 'bytes'),
        fileName: any(named: 'fileName'),
      ),
    );
  });

  test('falls back to bytes upload when picker returns no path', () async {
    final preparedAttachment = HashtreePreparedAttachment(
      nhash: 'nhash1abc123',
      link: 'nhash1abc123/photo.png',
      filename: 'photo.png',
      encryptedHashHex: 'deadbeef',
      encryptedBytes: Uint8List.fromList(<int>[7, 8, 9]),
    );
    final picked = PlatformFile(
      name: 'photo.png',
      size: 3,
      path: null,
      bytes: Uint8List.fromList(const [1, 2, 3]),
    );

    when(
      () => service.prepareBytes(
        bytes: any(named: 'bytes'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => preparedAttachment);
    when(
      () => service.uploadPreparedAttachment(any()),
    ).thenAnswer((_) async {});

    final uploaded = await uploadPickedAttachment(
      pickedFile: picked,
      service: service,
    );

    expect(uploaded.nhash, preparedAttachment.nhash);
    expect(uploaded.link, preparedAttachment.link);
    expect(uploaded.filename, preparedAttachment.filename);
    expect(uploaded.encryptedHashHex, preparedAttachment.encryptedHashHex);
    verify(
      () => service.prepareBytes(
        bytes: any(named: 'bytes'),
        fileName: 'photo.png',
      ),
    ).called(1);
    verify(
      () => service.uploadPreparedAttachment(preparedAttachment),
    ).called(1);
    verifyNever(
      () => service.prepareFile(
        filePath: any(named: 'filePath'),
        fileName: any(named: 'fileName'),
      ),
    );
  });
}
