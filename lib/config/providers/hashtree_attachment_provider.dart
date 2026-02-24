import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/hashtree_attachment_service.dart';
import 'auth_provider.dart';

final hashtreeAttachmentServiceProvider = Provider<HashtreeAttachmentService>((
  ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  return HashtreeAttachmentService(authRepository);
});
