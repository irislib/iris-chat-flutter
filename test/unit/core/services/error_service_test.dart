import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris_chat/core/services/error_service.dart';

void main() {
  group('ErrorService PlatformException mapping', () {
    test('maps self-invite NdrError to clear validation message', () {
      final error = PlatformException(
        code: 'NdrError',
        message: 'Invite("Cannot accept invite from this device")',
      );

      final mapped = AppError.from(error);

      expect(mapped.type, AppErrorType.validation);
      expect(mapped.message, contains('created by this same device'));
      expect(mapped.isRetryable, isFalse);
    });

    test('keeps generic platform message for unknown platform failures', () {
      final error = PlatformException(
        code: 'SomethingElse',
        message: 'native panic',
      );

      final mapped = AppError.from(error);

      expect(mapped.type, AppErrorType.unknown);
      expect(mapped.message, 'A platform error occurred. Please try again.');
      expect(mapped.isRetryable, isTrue);
    });
  });
}
