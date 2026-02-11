class UserModel {
  const UserModel({
    required this.id,
    this.phone,
    this.email,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String? phone;
  final String? email;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'email': email,
        'created_at': createdAt.toIso8601String(),
      };
}
