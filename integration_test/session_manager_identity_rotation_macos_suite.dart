import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iris_chat/core/services/nostr_service.dart';
import 'package:iris_chat/core/services/secure_storage_service.dart';
import 'package:iris_chat/core/services/session_manager_service.dart';
import 'package:iris_chat/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:path_provider/path_provider.dart';

Future<void> _clearNdrStorageDir() async {
  final supportDir = await getApplicationSupportDirectory();
  final ndrDir = Directory('${supportDir.path}/ndr');
  if (ndrDir.existsSync()) {
    await ndrDir.delete(recursive: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'session manager rebinds to new identity after logout + signup (macOS)',
    (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());

      if (!Platform.isMacOS) {
        return;
      }

      final storage = SecureStorageService();
      final repo = AuthRepositoryImpl(storage);
      final nostr = NostrService(relayUrls: const <String>[]);

      await storage.clearIdentity();
      await _clearNdrStorageDir();

      final firstIdentity = await repo.createIdentity();
      final firstManager = SessionManagerService(nostr, repo);
      await firstManager.start();
      expect(firstManager.ownerPubkeyHex, firstIdentity.pubkeyHex);
      await firstManager.dispose();

      await repo.logout();
      expect(await repo.getPrivateKey(), isNull);

      final secondIdentity = await repo.createIdentity();
      final secondManager = SessionManagerService(nostr, repo);
      await secondManager.start();
      expect(secondIdentity.pubkeyHex, isNot(firstIdentity.pubkeyHex));
      expect(secondManager.ownerPubkeyHex, secondIdentity.pubkeyHex);

      await secondManager.dispose();
      await storage.clearIdentity();
      await _clearNdrStorageDir();
      await nostr.disconnect();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
