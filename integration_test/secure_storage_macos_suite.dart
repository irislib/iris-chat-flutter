import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iris_chat/core/services/secure_storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'secure storage write/read works on macOS',
    (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());

      if (!Platform.isMacOS) {
        return;
      }

      final service = SecureStorageService();
      final privkeyHex = 'a' * 64;
      final pubkeyHex = 'b' * 64;

      await service.clearIdentity();
      await service.saveIdentity(privkeyHex: privkeyHex, pubkeyHex: pubkeyHex);

      expect(await service.getPrivateKey(), privkeyHex);
      expect(await service.getPublicKey(), pubkeyHex);

      await service.clearIdentity();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
