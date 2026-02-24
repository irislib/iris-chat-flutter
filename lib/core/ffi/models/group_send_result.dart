class GroupSendResult {
  const GroupSendResult({
    required this.outerEventJson,
    required this.innerEventJson,
    required this.outerEventId,
    required this.innerEventId,
  });

  factory GroupSendResult.fromMap(Map<String, dynamic> map) {
    return GroupSendResult(
      outerEventJson: map['outerEventJson'] as String? ?? '',
      innerEventJson: map['innerEventJson'] as String? ?? '',
      outerEventId: map['outerEventId'] as String? ?? '',
      innerEventId: map['innerEventId'] as String? ?? '',
    );
  }

  final String outerEventJson;
  final String innerEventJson;
  final String outerEventId;
  final String innerEventId;
}
