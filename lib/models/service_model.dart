class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.profileId,
    required this.name,
    required this.priceInr,
    this.description,
    this.deliveryDays,
    this.demoVideoUrl,
    this.demoImageUrl,
    this.categoryId,
    this.addonsJson,
    this.isActive = true,
    required this.createdAt,
    this.profileDisplayName,
    this.categoryName,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      name: json['name'] as String,
      priceInr: (json['price_inr'] as num).toDouble(),
      description: json['description'] as String?,
      deliveryDays: (json['delivery_days'] as num?)?.toInt(),
      demoVideoUrl: json['demo_video_url'] as String?,
      demoImageUrl: json['demo_image_url'] as String?,
      categoryId: json['category_id'] as String?,
      addonsJson: json['addons_json'],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      profileDisplayName: json['profile_display_name'] as String?,
      categoryName: json['categories'] != null && json['categories'] is Map
          ? (json['categories'] as Map)['name'] as String?
          : null,
    );
  }

  final String id;
  final String profileId;
  final String name;
  final double priceInr;
  final String? description;
  final int? deliveryDays;
  final String? demoVideoUrl;
  final String? demoImageUrl;
  final String? categoryId;
  final dynamic addonsJson;
  final bool isActive;
  final DateTime createdAt;
  final String? profileDisplayName;
  final String? categoryName;
}
