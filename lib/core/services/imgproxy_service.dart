import 'dart:convert';

import 'package:crypto/crypto.dart';

class ImgproxyConfig {
  const ImgproxyConfig({
    required this.enabled,
    this.url = defaultUrl,
    this.keyHex = defaultKeyHex,
    this.saltHex = defaultSaltHex,
  });

  static const String defaultUrl = 'https://imgproxy.iris.to';
  static const String defaultKeyHex =
      'f66233cb160ea07078ff28099bfa3e3e654bc10aa4a745e12176c433d79b8996';
  static const String defaultSaltHex =
      '5e608e60945dcd2a787e8465d76ba34149894765061d39287609fb9d776caa0c';

  final bool enabled;
  final String url;
  final String keyHex;
  final String saltHex;

  String get resolvedUrl {
    final trimmed = url.trim();
    return trimmed.isEmpty ? defaultUrl : trimmed;
  }

  String get resolvedKeyHex {
    final trimmed = keyHex.trim().toLowerCase();
    return trimmed.isEmpty ? defaultKeyHex : trimmed;
  }

  String get resolvedSaltHex {
    final trimmed = saltHex.trim().toLowerCase();
    return trimmed.isEmpty ? defaultSaltHex : trimmed;
  }

  ImgproxyConfig copyWith({
    bool? enabled,
    String? url,
    String? keyHex,
    String? saltHex,
  }) {
    return ImgproxyConfig(
      enabled: enabled ?? this.enabled,
      url: url ?? this.url,
      keyHex: keyHex ?? this.keyHex,
      saltHex: saltHex ?? this.saltHex,
    );
  }
}

class ImgproxyService {
  const ImgproxyService(this.config);

  final ImgproxyConfig config;

  String proxiedUrl(
    String originalSrc, {
    int? width,
    int? height,
    bool square = false,
  }) {
    final input = originalSrc.trim();
    if (input.isEmpty || !config.enabled) {
      return originalSrc;
    }

    if (input.startsWith('data:') || input.startsWith('blob:')) {
      return originalSrc;
    }

    final sourceUri = Uri.tryParse(input);
    if (sourceUri == null || !_isHttpUrl(sourceUri)) {
      return originalSrc;
    }

    final proxyBase = config.resolvedUrl;
    final proxyUri = Uri.tryParse(proxyBase);
    if (proxyUri == null || !_isHttpUrl(proxyUri)) {
      return originalSrc;
    }

    if (input.startsWith(proxyBase)) {
      return originalSrc;
    }

    final resizeWidth = _normalizedDimension(width, fallback: height);
    final resizeHeight = _normalizedDimension(height, fallback: width);

    final options = <String>[];
    if (resizeWidth != null && resizeHeight != null) {
      final mode = square ? 'fill' : 'fit';
      options.add('rs:$mode:$resizeWidth:$resizeHeight');
    }
    options.add('dpr:2');

    final encodedSource = base64Url
        .encode(utf8.encode(input))
        .replaceAll('=', '');
    final path = '/${options.join('/')}/$encodedSource';
    final signature = _sign(path);
    if (signature == null) {
      return originalSrc;
    }

    final trimmedBase = proxyBase.endsWith('/')
        ? proxyBase.substring(0, proxyBase.length - 1)
        : proxyBase;

    return '$trimmedBase/$signature$path';
  }

  String? _sign(String path) {
    final keyBytes = _decodeHex(config.resolvedKeyHex);
    final saltBytes = _decodeHex(config.resolvedSaltHex);
    if (keyBytes == null || saltBytes == null) return null;

    final data = <int>[...saltBytes, ...utf8.encode(path)];
    final digest = Hmac(sha256, keyBytes).convert(data).bytes;
    return base64Url.encode(digest).replaceAll('=', '');
  }

  List<int>? _decodeHex(String hex) {
    final normalized = hex.trim().toLowerCase();
    if (normalized.isEmpty || normalized.length.isOdd) return null;
    if (!RegExp(r'^[0-9a-f]+$').hasMatch(normalized)) return null;

    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      final value = int.tryParse(normalized.substring(i, i + 2), radix: 16);
      if (value == null) return null;
      bytes.add(value);
    }
    return bytes;
  }

  bool _isHttpUrl(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty;
  }

  int? _normalizedDimension(int? value, {required int? fallback}) {
    final candidate = value ?? fallback;
    if (candidate == null || candidate <= 0) return null;
    return candidate;
  }
}
