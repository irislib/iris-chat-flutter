import 'package:file_picker/file_picker.dart';

import '../../../../core/services/hashtree_attachment_service.dart';

Future<HashtreePreparedAttachment> preparePickedAttachment({
  required PlatformFile pickedFile,
  required HashtreeAttachmentService service,
}) async {
  final fileName = pickedFile.name.trim();
  if (fileName.isEmpty) {
    throw const HashtreeUploadException('Selected attachment has no filename.');
  }

  final filePath = pickedFile.path?.trim();
  if (filePath != null && filePath.isNotEmpty) {
    return service.prepareFile(filePath: filePath, fileName: fileName);
  }

  final bytes = pickedFile.bytes;
  if (bytes != null && bytes.isNotEmpty) {
    return service.prepareBytes(bytes: bytes, fileName: fileName);
  }

  throw const HashtreeUploadException(
    'Selected attachment is unreadable (no file path or bytes).',
  );
}

Future<HashtreeUploadedAttachment> uploadPickedAttachment({
  required PlatformFile pickedFile,
  required HashtreeAttachmentService service,
}) async {
  final prepared = await preparePickedAttachment(
    pickedFile: pickedFile,
    service: service,
  );
  await service.uploadPreparedAttachment(prepared);
  return prepared.toUploadedAttachment();
}
