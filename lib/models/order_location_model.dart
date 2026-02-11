class OrderLocationModel {
  const OrderLocationModel({
    required this.id,
    required this.orderId,
    required this.lat,
    required this.lng,
    required this.sharedBy,
    required this.createdAt,
  });

  factory OrderLocationModel.fromJson(Map<String, dynamic> json) {
    return OrderLocationModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      sharedBy: json['shared_by'] as String,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String orderId;
  final double lat;
  final double lng;
  final String sharedBy;
  final DateTime createdAt;
}
