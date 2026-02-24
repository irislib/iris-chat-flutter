import 'dart:convert';
import 'dart:typed_data';

import 'package:bech32/bech32.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

final RegExp _fileLinkRegex = RegExp(
  r'(?:htree://|nhash://)?nhash1[a-z0-9]+/[^\s]+',
  caseSensitive: false,
);

/// Parsed hashtree attachment link inside a message.
class HashtreeFileLink {
  const HashtreeFileLink({
    required this.nhash,
    required this.filename,
    required this.filenameEncoded,
  });

  final String nhash;
  final String filename;
  final String filenameEncoded;

  String get rawLink => '$nhash/$filenameEncoded';
}

/// Result of stripping hashtree links from message text.
class HashtreeFileLinkExtraction {
  const HashtreeFileLinkExtraction({required this.text, required this.links});

  final String text;
  final List<HashtreeFileLink> links;
}

/// Content-hash-key encrypted blob ready for Blossom upload.
class HashtreeEncryptedBlob {
  const HashtreeEncryptedBlob({
    required this.encryptedBytes,
    required this.decryptKey,
    required this.encryptedHash,
  });

  final Uint8List encryptedBytes;
  final Uint8List decryptKey;
  final Uint8List encryptedHash;
}

/// Decoded payload from an `nhash` reference.
///
/// TLV tags:
/// - 0: encrypted blob hash
/// - 5: decrypt key (optional)
class DecodedNhash {
  const DecodedNhash({required this.hash, required this.decryptKey});

  final Uint8List hash;
  final Uint8List? decryptKey;
}

String formatHashtreeFileLink(String nhash, String filename) {
  return '$nhash/${Uri.encodeComponent(filename)}';
}

HashtreeFileLink? parseHashtreeFileLink(String value) {
  var cleaned = value.trim();
  if (cleaned.startsWith('htree://')) {
    cleaned = cleaned.substring('htree://'.length);
  } else if (cleaned.startsWith('nhash://')) {
    cleaned = cleaned.substring('nhash://'.length);
  }

  final slash = cleaned.indexOf('/');
  if (slash <= 0 || slash == cleaned.length - 1) return null;

  final nhash = cleaned.substring(0, slash).trim();
  if (!nhash.toLowerCase().startsWith('nhash1')) return null;

  final filenameEncoded = cleaned.substring(slash + 1).trim();
  if (filenameEncoded.isEmpty) return null;

  String filename;
  try {
    filename = Uri.decodeComponent(filenameEncoded);
  } catch (_) {
    filename = filenameEncoded;
  }

  return HashtreeFileLink(
    nhash: nhash,
    filename: filename,
    filenameEncoded: filenameEncoded,
  );
}

HashtreeFileLinkExtraction extractHashtreeFileLinks(String text) {
  final links = <HashtreeFileLink>[];

  final stripped = text.replaceAllMapped(_fileLinkRegex, (match) {
    final parsed = parseHashtreeFileLink(match.group(0) ?? '');
    if (parsed == null) return match.group(0) ?? '';
    links.add(parsed);
    return '';
  });

  return HashtreeFileLinkExtraction(text: stripped.trim(), links: links);
}

String appendHashtreeLinksToMessage(String text, List<String> links) {
  final trimmed = text.trim();
  final normalizedLinks = links
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  if (normalizedLinks.isEmpty) return trimmed;
  if (trimmed.isEmpty) return normalizedLinks.join('\n');
  return '$trimmed\n${normalizedLinks.join('\n')}';
}

DecodedNhash? decodeNhash(String nhash) {
  try {
    final decoded = bech32.decode(nhash, 4096);
    if (decoded.hrp.toLowerCase() != 'nhash') return null;

    final data = _convertBits(decoded.data, fromBits: 5, toBits: 8, pad: false);
    if (data.isEmpty) return null;

    Uint8List? hash;
    Uint8List? decryptKey;

    var i = 0;
    while (i < data.length) {
      if (i + 2 > data.length) return null;
      final tag = data[i++];
      final len = data[i++];
      if (len <= 0 || i + len > data.length) return null;
      final value = Uint8List.fromList(data.sublist(i, i + len));
      i += len;

      switch (tag) {
        case 0:
          hash = value;
          break;
        case 5:
          decryptKey = value;
          break;
        default:
          // Ignore unknown TLVs for forward compatibility.
          break;
      }
    }

    if (hash == null || hash.length != 32) return null;
    if (decryptKey != null && decryptKey.length != 32) return null;
    return DecodedNhash(hash: hash, decryptKey: decryptKey);
  } catch (_) {
    return null;
  }
}

Future<Uint8List> decryptChkDownload({
  required Uint8List encryptedBytes,
  required Uint8List decryptKey,
}) async {
  if (decryptKey.length != 32) {
    throw ArgumentError.value(
      decryptKey.length,
      'decryptKey.length',
      'must be 32 bytes',
    );
  }
  if (encryptedBytes.length < 16) {
    throw ArgumentError.value(
      encryptedBytes.length,
      'encryptedBytes.length',
      'must be >= 16 bytes',
    );
  }

  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final derived = await hkdf.deriveKey(
    secretKey: SecretKey(decryptKey),
    nonce: Uint8List.fromList(utf8.encode('hashtree-chk')),
    info: Uint8List.fromList(utf8.encode('encryption-key')),
  );
  final derivedKeyBytes = Uint8List.fromList(await derived.extractBytes());

  final cipherText = encryptedBytes.sublist(0, encryptedBytes.length - 16);
  final macBytes = encryptedBytes.sublist(encryptedBytes.length - 16);
  final box = SecretBox(cipherText, nonce: Uint8List(12), mac: Mac(macBytes));

  final aes = AesGcm.with256bits();
  final plaintext = await aes.decrypt(
    box,
    secretKey: SecretKey(derivedKeyBytes),
  );
  return Uint8List.fromList(plaintext);
}

bool isImageFilename(String filename) {
  final ext = p.extension(filename).toLowerCase();
  return switch (ext) {
    '.jpg' ||
    '.jpeg' ||
    '.png' ||
    '.gif' ||
    '.webp' ||
    '.svg' ||
    '.bmp' => true,
    _ => false,
  };
}

String buildAttachmentAwarePreview(String text, {int maxLength = 50}) {
  final extracted = extractHashtreeFileLinks(text);
  var preview = extracted.text.trim();

  if (preview.isEmpty && extracted.links.isNotEmpty) {
    preview = extracted.links.length == 1
        ? 'Attachment: ${extracted.links.first.filename}'
        : '${extracted.links.length} attachments';
  }

  if (preview.length <= maxLength) return preview;
  return '${preview.substring(0, maxLength)}...';
}

Future<HashtreeEncryptedBlob> encryptChkForUpload(Uint8List plaintext) async {
  final decryptKey = Uint8List.fromList(crypto.sha256.convert(plaintext).bytes);

  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final derived = await hkdf.deriveKey(
    secretKey: SecretKey(decryptKey),
    nonce: Uint8List.fromList(utf8.encode('hashtree-chk')),
    info: Uint8List.fromList(utf8.encode('encryption-key')),
  );
  final derivedKeyBytes = Uint8List.fromList(await derived.extractBytes());

  final aes = AesGcm.with256bits();
  final box = await aes.encrypt(
    plaintext,
    secretKey: SecretKey(derivedKeyBytes),
    nonce: Uint8List(12),
  );

  final encryptedBytes = Uint8List.fromList([
    ...box.cipherText,
    ...box.mac.bytes,
  ]);
  final encryptedHash = Uint8List.fromList(
    crypto.sha256.convert(encryptedBytes).bytes,
  );

  return HashtreeEncryptedBlob(
    encryptedBytes: encryptedBytes,
    decryptKey: decryptKey,
    encryptedHash: encryptedHash,
  );
}

/// Encode hashtree TLV bech32 `nhash`.
///
/// TLV tags:
/// - 0: 32-byte encrypted blob hash
/// - 5: optional 32-byte decrypt key
String encodeNhash({required Uint8List hash, Uint8List? decryptKey}) {
  if (hash.length != 32) {
    throw ArgumentError.value(hash.length, 'hash.length', 'must be 32 bytes');
  }
  if (decryptKey != null && decryptKey.length != 32) {
    throw ArgumentError.value(
      decryptKey.length,
      'decryptKey.length',
      'must be 32 bytes',
    );
  }

  final tlv = BytesBuilder(copy: false)
    ..addByte(0)
    ..addByte(32)
    ..add(hash);

  if (decryptKey != null) {
    tlv
      ..addByte(5)
      ..addByte(32)
      ..add(decryptKey);
  }

  final data5 = _convertBits(tlv.toBytes(), fromBits: 8, toBits: 5, pad: true);
  // nhash identifiers with decrypt keys are longer than BIP173's 90-char limit.
  return bech32.encode(Bech32('nhash', data5), 4096);
}

String hexEncode(Uint8List bytes) {
  final buffer = StringBuffer();
  for (final b in bytes) {
    buffer.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

List<int> _convertBits(
  List<int> data, {
  required int fromBits,
  required int toBits,
  required bool pad,
}) {
  var acc = 0;
  var bits = 0;
  final result = <int>[];
  final maxValue = (1 << toBits) - 1;

  for (final value in data) {
    if (value < 0 || (value >> fromBits) != 0) {
      throw ArgumentError.value(value, 'value', 'out of range');
    }
    acc = (acc << fromBits) | value;
    bits += fromBits;
    while (bits >= toBits) {
      bits -= toBits;
      result.add((acc >> bits) & maxValue);
    }
  }

  if (pad) {
    if (bits > 0) {
      result.add((acc << (toBits - bits)) & maxValue);
    }
  } else {
    if (bits >= fromBits) {
      throw ArgumentError('illegal zero padding');
    }
    if (((acc << (toBits - bits)) & maxValue) != 0) {
      throw ArgumentError('non-zero padding');
    }
  }

  return result;
}
