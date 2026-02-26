class FfiGroupData {
  const FfiGroupData({
    required this.id,
    required this.name,
    this.description,
    this.picture,
    required this.members,
    required this.admins,
    required this.createdAtMs,
    this.secret,
    this.accepted,
  });

  const FfiGroupData.empty()
    : id = '',
      name = '',
      description = null,
      picture = null,
      members = const <String>[],
      admins = const <String>[],
      createdAtMs = 0,
      secret = null,
      accepted = null;

  factory FfiGroupData.fromMap(Map<String, dynamic> map) {
    return FfiGroupData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      picture: map['picture'] as String?,
      members: (map['members'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      admins: (map['admins'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
      secret: map['secret'] as String?,
      accepted: map['accepted'] as bool?,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? picture;
  final List<String> members;
  final List<String> admins;
  final int createdAtMs;
  final String? secret;
  final bool? accepted;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'picture': picture,
      'members': members,
      'admins': admins,
      'createdAtMs': createdAtMs,
      'secret': secret,
      'accepted': accepted,
    };
  }
}
