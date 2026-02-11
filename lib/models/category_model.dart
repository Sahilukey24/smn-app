class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.roleType,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      roleType: json['role_type'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String roleType;
  final int sortOrder;
}
