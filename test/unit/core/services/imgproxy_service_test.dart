import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/imgproxy_service.dart';

void main() {
  group('ImgproxyService', () {
    test('returns original URL when disabled', () {
      const input = 'https://example.com/avatar.jpg';
      const service = ImgproxyService(
        ImgproxyConfig(enabled: false),
      );

      expect(service.proxiedUrl(input, width: 64, height: 64), input);
    });

    test('returns original URL for data and blob URLs', () {
      const service = ImgproxyService(
        ImgproxyConfig(enabled: true),
      );

      expect(
        service.proxiedUrl('data:image/png;base64,abc'),
        'data:image/png;base64,abc',
      );
      expect(
        service.proxiedUrl('blob:https://example.com/123'),
        'blob:https://example.com/123',
      );
    });

    test('generates deterministic signed proxy URL with resize options', () {
      const input = 'https://example.com/avatar.jpg';
      const service = ImgproxyService(
        ImgproxyConfig(enabled: true),
      );

      final url = service.proxiedUrl(
        input,
        width: 64,
        height: 64,
        square: true,
      );

      expect(url, startsWith('https://imgproxy.iris.to/'));
      expect(url, contains('/rs:fill:64:64/'));
      expect(url, contains('/dpr:2/'));
      expect(url, contains('aHR0cHM6Ly9leGFtcGxlLmNvbS9hdmF0YXIuanBn'));
      expect(
        service.proxiedUrl(input, width: 64, height: 64, square: true),
        url,
      );
    });

    test('returns original URL when key/salt are invalid hex', () {
      const input = 'https://example.com/avatar.jpg';
      const service = ImgproxyService(
        ImgproxyConfig(
          enabled: true,
          keyHex: 'not-hex',
          saltHex: 'also-not-hex',
        ),
      );

      expect(service.proxiedUrl(input), input);
    });
  });
}
