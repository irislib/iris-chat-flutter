import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iris_chat/core/services/secure_storage_service.dart';
import 'package:iris_chat/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'logout clears key and next signup rotates identity keypair (macOS)',
    (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());

      if (!Platform.isMacOS) {
        return;
      }

      final storage = SecureStorageService();
      final repo = AuthRepositoryImpl(storage);

      await storage.clearIdentity();

      final firstIdentity = await repo.createIdentity();
      final firstPrivkey = await repo.getPrivateKey();
      expect(firstPrivkey, isNotNull);
      expect(firstIdentity.pubkeyHex, isNotEmpty);

      await repo.logout();
      expect(await repo.getPrivateKey(), isNull);
      expect(await repo.getCurrentIdentity(), isNull);

      final secondIdentity = await repo.createIdentity();
      final secondPrivkey = await repo.getPrivateKey();
      expect(secondPrivkey, isNotNull);
      expect(secondIdentity.pubkeyHex, isNotEmpty);

      expect(secondPrivkey, isNot(firstPrivkey));
      expect(secondIdentity.pubkeyHex, isNot(firstIdentity.pubkeyHex));

      await storage.clearIdentity();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
