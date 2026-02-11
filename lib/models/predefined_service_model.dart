class PredefinedServiceModel {
  const PredefinedServiceModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.sortOrder = 0,
  });

  factory PredefinedServiceModel.fromJson(Map<String, dynamic> json) {
    return PredefinedServiceModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String categoryId;
  final String name;
  final int sortOrder;
}
