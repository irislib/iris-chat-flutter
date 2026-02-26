class GroupCreateFanout {
  const GroupCreateFanout({
    required this.enabled,
    required this.attempted,
    required this.succeeded,
    required this.failed,
  });

  factory GroupCreateFanout.fromMap(Map<String, dynamic> map) {
    return GroupCreateFanout(
      enabled: map['enabled'] as bool? ?? false,
      attempted: (map['attempted'] as num?)?.toInt() ?? 0,
      succeeded: (map['succeeded'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      failed: (map['failed'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  final bool enabled;
  final int attempted;
  final List<String> succeeded;
  final List<String> failed;
}
