import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/utils/hashtree_attachments.dart';

void main() {
  group('hashtree attachment links', () {
    test('formats and parses nhash links', () {
      final link = formatHashtreeFileLink('nhash1abc123', 'hieno tanssi.mp4');
      expect(link, 'nhash1abc123/hieno%20tanssi.mp4');

      final parsed = parseHashtreeFileLink(link);
      expect(parsed, isNotNull);
      expect(parsed!.nhash, 'nhash1abc123');
      expect(parsed.filename, 'hieno tanssi.mp4');
      expect(parsed.filenameEncoded, 'hieno%20tanssi.mp4');
    });

    test('parses optional schemes', () {
      final parsed = parseHashtreeFileLink('htree://nhash1abc123/test.jpg');
      expect(parsed, isNotNull);
      expect(parsed!.nhash, 'nhash1abc123');
      expect(parsed.filename, 'test.jpg');
    });

    test('extracts links and strips them from text', () {
      final extracted = extractHashtreeFileLinks(
        'hello\nnhash1abc123/file.png\nand htree://nhash1def456/video.mp4',
      );

      expect(extracted.links.length, 2);
      expect(extracted.links[0].filename, 'file.png');
      expect(extracted.links[1].filename, 'video.mp4');
      expect(extracted.text, 'hello\n\nand');
    });

    test('builds preview text from attachment-only message', () {
      final preview = buildAttachmentAwarePreview(
        'nhash1abc123/file.png',
        maxLength: 80,
      );
      expect(preview, 'Attachment: file.png');
    });

    test('appends links to message content', () {
      final content = appendHashtreeLinksToMessage('Look at this', const [
        'nhash1abc123/one.png',
        'nhash1def456/two.jpg',
      ]);
      expect(
        content,
        'Look at this\nnhash1abc123/one.png\nnhash1def456/two.jpg',
      );
    });
  });

  group('hashtree interop vectors', () {
    test('encodes nhash with decrypt key like hashtree-core', () {
      final nhash = encodeNhash(
        hash: Uint8List.fromList(
          _decodeHex(
            'fe6064a7b5243aee66f8ddcd2218c38475206ff171328b0e7b39c69ecb888864',
          ),
        ),
        decryptKey: Uint8List.fromList(
          _decodeHex(
            '880b78990f72e4ac5a452c4a691823e83ab94a31b8b6ae1fc4db6410c4504339',
          ),
        ),
      );

      expect(
        nhash,
        'nhash1qqs0ucry576jgwhwvmudmnfzrrpcgafqdlchzv5tpeann357ewygseq9yzyqk7yepaewftz6g5ky56gcy05r4w22xxutdtslcndkgyxy2ppnj7999sn',
      );
    });

    test(
      'CHK encrypt + hash matches hashtree-core output for sample bytes',
      () async {
        final plaintext = Uint8List.fromList(utf8.encode('hello hashtree'));
        final encrypted = await encryptChkForUpload(plaintext);

        expect(
          hexEncode(encrypted.decryptKey),
          '880b78990f72e4ac5a452c4a691823e83ab94a31b8b6ae1fc4db6410c4504339',
        );
        expect(
          hexEncode(encrypted.encryptedHash),
          'fe6064a7b5243aee66f8ddcd2218c38475206ff171328b0e7b39c69ecb888864',
        );
      },
    );

    test('decodes nhash and decrypts CHK payload', () async {
      final plaintext = Uint8List.fromList(utf8.encode('hello hashtree'));
      final encrypted = await encryptChkForUpload(plaintext);
      final nhash = encodeNhash(
        hash: encrypted.encryptedHash,
        decryptKey: encrypted.decryptKey,
      );

      final decoded = decodeNhash(nhash);
      expect(decoded, isNotNull);
      expect(hexEncode(decoded!.hash), hexEncode(encrypted.encryptedHash));
      expect(hexEncode(decoded.decryptKey!), hexEncode(encrypted.decryptKey));

      final decrypted = await decryptChkDownload(
        encryptedBytes: encrypted.encryptedBytes,
        decryptKey: decoded.decryptKey!,
      );
      expect(utf8.decode(decrypted), 'hello hashtree');
    });

    test('isImageFilename follows notedeck image extension set', () {
      expect(isImageFilename('photo.jpg'), isTrue);
      expect(isImageFilename('photo.JPEG'), isTrue);
      expect(isImageFilename('clip.mp4'), isFalse);
      expect(isImageFilename('document.pdf'), isFalse);
    });
  });
}

List<int> _decodeHex(String input) {
  if (input.length.isOdd) {
    throw ArgumentError.value(input, 'input', 'hex string length must be even');
  }

  final out = <int>[];
  for (var i = 0; i < input.length; i += 2) {
    out.add(int.parse(input.substring(i, i + 2), radix: 16));
  }
  return out;
}
