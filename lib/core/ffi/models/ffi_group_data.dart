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
