import 'dart:typed_data';

import 'package:bech32/bech32.dart';
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
