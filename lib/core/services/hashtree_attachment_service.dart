import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../ffi/ndr_ffi.dart';
import '../utils/hashtree_attachments.dart';

class HashtreeUploadException implements Exception {
  const HashtreeUploadException(this.message);

  final String message;

  @override
  String toString() => 'HashtreeUploadException: $message';
}

class HashtreeUploadedAttachment {
  const HashtreeUploadedAttachment({
    required this.nhash,
    required this.link,
    required this.filename,
    required this.encryptedHashHex,
  });

  final String nhash;
  final String link;
  final String filename;
  final String encryptedHashHex;
}

class HashtreePreparedAttachment {
  const HashtreePreparedAttachment({
    required this.nhash,
    required this.link,
    required this.filename,
    required this.encryptedHashHex,
    required this.encryptedBytes,
  });

  final String nhash;
  final String link;
  final String filename;
  final String encryptedHashHex;
  final Uint8List encryptedBytes;

  HashtreeUploadedAttachment toUploadedAttachment() {
    return HashtreeUploadedAttachment(
      nhash: nhash,
      link: link,
      filename: filename,
      encryptedHashHex: encryptedHashHex,
    );
  }
}

abstract class HashtreeAttachmentFfi {
  Future<String> nhashFromFile(String filePath);

  Future<String> uploadFile({
    required String privkeyHex,
    required String filePath,
    required List<String> readServers,
    required List<String> writeServers,
  });

  Future<Uint8List> downloadBytes({
    required String nhash,
    required List<String> readServers,
  });

  Future<void> downloadToFile({
    required String nhash,
    required String outputPath,
    required List<String> readServers,
  });
}

class NdrHashtreeAttachmentFfi implements HashtreeAttachmentFfi {
  const NdrHashtreeAttachmentFfi();

  @override
  Future<String> nhashFromFile(String filePath) {
    return NdrFfi.hashtreeNhashFromFile(filePath);
  }

  @override
  Future<String> uploadFile({
    required String privkeyHex,
    required String filePath,
    required List<String> readServers,
    required List<String> writeServers,
  }) {
    return NdrFfi.hashtreeUploadFile(
      privkeyHex: privkeyHex,
      filePath: filePath,
      readServers: readServers,
      writeServers: writeServers,
    );
  }

  @override
  Future<Uint8List> downloadBytes({
    required String nhash,
    required List<String> readServers,
  }) {
    return NdrFfi.hashtreeDownloadBytes(nhash: nhash, readServers: readServers);
  }

  @override
  Future<void> downloadToFile({
    required String nhash,
    required String outputPath,
    required List<String> readServers,
  }) {
    return NdrFfi.hashtreeDownloadToFile(
      nhash: nhash,
      outputPath: outputPath,
      readServers: readServers,
    );
  }
}

/// Uploads attachments using hashtree CHK+Blossom via ndr-ffi.
class HashtreeAttachmentService {
  HashtreeAttachmentService(
    this._authRepository, {
    HashtreeAttachmentFfi? ffi,
    List<Uri>? readServers,
    List<Uri>? writeServers,
  }) : _ffi = ffi ?? const NdrHashtreeAttachmentFfi() {
    final resolvedWriteServers = writeServers ?? _defaultWriteServers();
    _writeServers = resolvedWriteServers;
    _readServers = _mergeReadServers(
      readServers ?? _defaultReadServers(),
      resolvedWriteServers,
    );
  }

  final AuthRepository _authRepository;
  final HashtreeAttachmentFfi _ffi;
  late final List<Uri> _readServers;
  late final List<Uri> _writeServers;
  final Map<String, String> _preparedFileByLink = {};
  final Set<String> _temporaryPreparedFiles = {};

  static List<Uri> _defaultReadServers() {
    const csv = String.fromEnvironment(
      'IRIS_HASHTREE_READ_SERVERS',
      defaultValue:
          'https://cdn.iris.to,https://hashtree.iris.to,https://upload.iris.to',
    );
    final out = <Uri>[];
    for (final raw in csv.split(',')) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final parsed = Uri.tryParse(trimmed);
      if (parsed == null || !parsed.hasScheme) continue;
      if (_isLocalServerUri(parsed)) continue;
      out.add(parsed);
    }
    return out;
  }

  static List<Uri> _defaultWriteServers() {
    const csv = String.fromEnvironment(
      'IRIS_HASHTREE_WRITE_SERVERS',
      defaultValue: 'https://upload.iris.to',
    );
    final out = <Uri>[];
    for (final raw in csv.split(',')) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final parsed = Uri.tryParse(trimmed);
      if (parsed == null || !parsed.hasScheme) continue;
      if (_isLocalServerUri(parsed)) continue;
      out.add(parsed);
    }
    if (out.isEmpty) {
      out.add(Uri.parse('https://upload.iris.to'));
    }
    return out;
  }

  static List<Uri> _mergeReadServers(List<Uri> read, List<Uri> write) {
    final merged = <Uri>[...read];
    final seen = merged.map((u) => u.toString()).toSet();
    for (final server in write) {
      final key = server.toString();
      if (seen.add(key)) merged.add(server);
    }
    return merged;
  }

  static bool _isLocalServerUri(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  List<String> get _readServerUrls =>
      _readServers.map((server) => server.toString()).toList(growable: false);

  List<String> get _writeServerUrls =>
      _writeServers.map((server) => server.toString()).toList(growable: false);

  Future<HashtreePreparedAttachment> prepareFile({
    required String filePath,
    String? fileName,
  }) async {
    final file = File(filePath);
    final name = (fileName != null && fileName.trim().isNotEmpty)
        ? fileName.trim()
        : p.basename(file.path);
    if (name.isEmpty) {
      throw const HashtreeUploadException('Attachment filename is empty.');
    }
    if (!file.existsSync()) {
      throw HashtreeUploadException(
        'Attachment file does not exist: $filePath',
      );
    }

    try {
      final nhash = await _ffi.nhashFromFile(file.path);
      final decoded = decodeNhash(nhash);
      if (decoded == null) {
        throw const HashtreeUploadException(
          'ndr-ffi returned an invalid attachment nhash.',
        );
      }

      final link = formatHashtreeFileLink(nhash, name);
      _preparedFileByLink[link] = file.path;

      return HashtreePreparedAttachment(
        nhash: nhash,
        link: link,
        filename: name,
        encryptedHashHex: hexEncode(decoded.hash),
        encryptedBytes: Uint8List(0),
      );
    } on PlatformException catch (e) {
      throw HashtreeUploadException(
        'Failed to prepare attachment via ndr-ffi: ${e.message ?? e.code}',
      );
    }
  }

  Future<HashtreePreparedAttachment> prepareBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final name = fileName.trim();
    if (name.isEmpty) {
      throw const HashtreeUploadException('Attachment filename is empty.');
    }
    if (bytes.isEmpty) {
      throw const HashtreeUploadException('Attachment file is empty.');
    }

    final safeName = p.basename(name);
    final tempPath = p.join(
      Directory.systemTemp.path,
      'iris-chat-attachment-${DateTime.now().microsecondsSinceEpoch}-$safeName',
    );
    final file = File(tempPath);
    try {
      await file.writeAsBytes(bytes, flush: true);
      final prepared = await prepareFile(filePath: tempPath, fileName: name);
      _temporaryPreparedFiles.add(tempPath);
      return prepared;
    } on FileSystemException catch (e) {
      throw HashtreeUploadException(
        'Failed to create temporary attachment file: ${e.message}',
      );
    }
  }

  Future<void> uploadPreparedAttachment(
    HashtreePreparedAttachment prepared,
  ) async {
    final sourcePath = _preparedFileByLink[prepared.link];
    if (sourcePath == null || sourcePath.isEmpty) {
      throw const HashtreeUploadException(
        'Prepared attachment source file is no longer available.',
      );
    }

    final privkeyHex = await _authRepository.getPrivateKey();
    if (privkeyHex == null || privkeyHex.isEmpty) {
      throw const HashtreeUploadException(
        'Missing private key for hashtree upload authorization.',
      );
    }

    try {
      final nhash = await _ffi.uploadFile(
        privkeyHex: privkeyHex,
        filePath: sourcePath,
        readServers: _readServerUrls,
        writeServers: _writeServerUrls,
      );
      if (nhash != prepared.nhash) {
        throw HashtreeUploadException(
          'Attachment nhash mismatch after upload (prepared=${prepared.nhash}, uploaded=$nhash).',
        );
      }

      _preparedFileByLink.remove(prepared.link);
      if (_temporaryPreparedFiles.remove(sourcePath)) {
        try {
          await File(sourcePath).delete();
        } catch (_) {
          // Best-effort cleanup for temporary prepared files.
        }
      }
    } on PlatformException catch (e) {
      throw HashtreeUploadException(
        'Attachment upload failed via ndr-ffi: ${e.message ?? e.code}',
      );
    }
  }

  Future<HashtreeUploadedAttachment> uploadFile({
    required String filePath,
    String? fileName,
  }) async {
    final prepared = await prepareFile(filePath: filePath, fileName: fileName);
    await uploadPreparedAttachment(prepared);
    return prepared.toUploadedAttachment();
  }

  Future<HashtreeUploadedAttachment> uploadBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final prepared = await prepareBytes(bytes: bytes, fileName: fileName);
    await uploadPreparedAttachment(prepared);
    return prepared.toUploadedAttachment();
  }

  Future<Uint8List> downloadFile({required HashtreeFileLink link}) async {
    try {
      return await _ffi.downloadBytes(
        nhash: link.nhash,
        readServers: _readServerUrls,
      );
    } on PlatformException catch (e) {
      throw HashtreeUploadException(
        'Attachment download failed via ndr-ffi: ${e.message ?? e.code}',
      );
    }
  }

  Future<void> downloadFileToPath({
    required HashtreeFileLink link,
    required String outputPath,
  }) async {
    final outFile = File(outputPath);
    await outFile.parent.create(recursive: true);
    try {
      await _ffi.downloadToFile(
        nhash: link.nhash,
        outputPath: outputPath,
        readServers: _readServerUrls,
      );
    } on PlatformException catch (e) {
      throw HashtreeUploadException(
        'Attachment download failed via ndr-ffi: ${e.message ?? e.code}',
      );
    }
  }
}
