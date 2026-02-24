class GroupDecryptedResult {
  const GroupDecryptedResult({
    required this.groupId,
    required this.senderEventPubkeyHex,
    required this.senderDevicePubkeyHex,
    this.senderOwnerPubkeyHex,
    required this.outerEventId,
    required this.outerCreatedAt,
    required this.keyId,
    required this.messageNumber,
    required this.innerEventJson,
    required this.innerEventId,
  });

  factory GroupDecryptedResult.fromMap(Map<String, dynamic> map) {
    return GroupDecryptedResult(
      groupId: map['groupId'] as String? ?? '',
      senderEventPubkeyHex: map['senderEventPubkeyHex'] as String? ?? '',
      senderDevicePubkeyHex: map['senderDevicePubkeyHex'] as String? ?? '',
      senderOwnerPubkeyHex: map['senderOwnerPubkeyHex'] as String?,
      outerEventId: map['outerEventId'] as String? ?? '',
      outerCreatedAt: (map['outerCreatedAt'] as num?)?.toInt() ?? 0,
      keyId: (map['keyId'] as num?)?.toInt() ?? 0,
      messageNumber: (map['messageNumber'] as num?)?.toInt() ?? 0,
      innerEventJson: map['innerEventJson'] as String? ?? '',
      innerEventId: map['innerEventId'] as String? ?? '',
    );
  }

  final String groupId;
  final String senderEventPubkeyHex;
  final String senderDevicePubkeyHex;
  final String? senderOwnerPubkeyHex;
  final String outerEventId;
  final int outerCreatedAt;
  final int keyId;
  final int messageNumber;
  final String innerEventJson;
  final String innerEventId;
}
