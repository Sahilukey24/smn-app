/// User profile matching Supabase `profiles` table.
class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'viewer',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String email;
  final String username;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'role': role,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  Profile copyWith({
    String? username,
    String? role,
    String? avatarUrl,
  }) {
    return Profile(
      id: id,
      email: email,
      username: username ?? this.username,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}
