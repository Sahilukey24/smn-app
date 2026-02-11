/// Product-first simple models (mock flow only).

class MockServiceModel {
  const MockServiceModel({
    required this.id,
    required this.title,
    required this.price,
    required this.creatorId,
    required this.description,
    this.creatorName = 'Creator',
    this.rating = 4.5,
    this.deliveryDays = 5,
  });

  final String id;
  final String title;
  final double price;
  final String creatorId;
  final String description;
  final String creatorName;
  final double rating;
  final int deliveryDays;
}

class MockOrderModel {
  const MockOrderModel({
    required this.id,
    required this.serviceId,
    required this.buyerId,
    required this.creatorId,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String serviceId;
  final String buyerId;
  final String creatorId;
  final double price;
  final String status; // pending_payment, in_progress, delivered, completed
  final DateTime createdAt;

  MockOrderModel copyWith({
    String? id,
    String? serviceId,
    String? buyerId,
    String? creatorId,
    double? price,
    String? status,
    DateTime? createdAt,
  }) {
    return MockOrderModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      buyerId: buyerId ?? this.buyerId,
      creatorId: creatorId ?? this.creatorId,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
