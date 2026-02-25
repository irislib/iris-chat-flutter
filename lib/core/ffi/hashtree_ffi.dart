library;

import 'package:flutter/services.dart';

/// Dart bindings for hashtree attachment operations.
///
/// Uses a dedicated platform channel so attachment APIs stay separate from
/// ndr-ffi message/session APIs.
class HashtreeFfi {
  static const _channel = MethodChannel('to.iris.chat/hashtree');

  /// Compute deterministic hashtree nhash for a local file without uploading.
  static Future<String> nhashFromFile(String filePath) async {
    final result = await _channel.invokeMethod<String>('nhashFromFile', {
      'filePath': filePath,
    });
    if (result == null || result.isEmpty) {
      throw PlatformException(
        code: 'Serialization',
        message: 'Failed to compute attachment nhash',
      );
    }
    return result;
  }

  /// Upload a local file to hashtree/Blossom and return its nhash.
  static Future<String> uploadFile({
    required String privkeyHex,
    required String filePath,
    required List<String> readServers,
    required List<String> writeServers,
  }) async {
    final result = await _channel.invokeMethod<String>('uploadFile', {
      'privkeyHex': privkeyHex,
      'filePath': filePath,
      'readServers': readServers,
      'writeServers': writeServers,
    });
    if (result == null || result.isEmpty) {
      throw PlatformException(
        code: 'Serialization',
        message: 'Failed to upload attachment',
      );
    }
    return result;
  }

  /// Download an attachment into memory.
  static Future<Uint8List> downloadBytes({
    required String nhash,
    required List<String> readServers,
  }) async {
    final result = await _channel.invokeMethod<Uint8List>('downloadBytes', {
      'nhash': nhash,
      'readServers': readServers,
    });
    if (result == null) {
      throw PlatformException(
        code: 'Serialization',
        message: 'Failed to download attachment',
      );
    }
    return result;
  }

  /// Download an attachment directly to disk.
  static Future<void> downloadToFile({
    required String nhash,
    required String outputPath,
    required List<String> readServers,
  }) async {
    await _channel.invokeMethod<void>('downloadToFile', {
      'nhash': nhash,
      'outputPath': outputPath,
      'readServers': readServers,
    });
  }
}
