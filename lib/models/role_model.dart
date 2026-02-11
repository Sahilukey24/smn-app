class RoleModel {
  const RoleModel({
    required this.id,
    required this.userId,
    required this.role,
    this.paidAt,
    this.verifiedAt,
    required this.createdAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'] as String) : null,
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at'] as String) : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String role;
  final DateTime? paidAt;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  bool get isPaid => paidAt != null;
}
