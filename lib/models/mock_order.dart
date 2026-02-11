/// In-memory order for business money flow (mock only).
class MockOrder {
  MockOrder({
    required this.id,
    required this.serviceName,
    required this.creatorName,
    required this.creatorId,
    required this.price,
    this.platformFee = 15,
    this.status = 'pending_payment',
    List<MockOrderMessage>? messages,
    List<MockOrderTimelineEvent>? timeline,
    this.deliveredFile,
    this.buyerId = 'business-1',
  })  : messages = messages ?? [],
        timeline = timeline ?? [];

  final String id;
  final String serviceName;
  final String creatorName;
  final String creatorId;
  final double price;
  final double platformFee;
  final String status; // pending_payment, in_progress, delivered, completed
  final List<MockOrderMessage> messages;
  final List<MockOrderTimelineEvent> timeline;
  final String? deliveredFile;
  final String buyerId;

  MockOrder copyWith({
    String? id,
    String? serviceName,
    String? creatorName,
    String? creatorId,
    double? price,
    double? platformFee,
    String? status,
    List<MockOrderMessage>? messages,
    List<MockOrderTimelineEvent>? timeline,
    String? deliveredFile,
    String? buyerId,
  }) {
    return MockOrder(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      creatorName: creatorName ?? this.creatorName,
      creatorId: creatorId ?? this.creatorId,
      price: price ?? this.price,
      platformFee: platformFee ?? this.platformFee,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      timeline: timeline ?? this.timeline,
      deliveredFile: deliveredFile ?? this.deliveredFile,
      buyerId: buyerId ?? this.buyerId,
    );
  }
}

class MockOrderMessage {
  const MockOrderMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String senderId; // 'buyer' | creatorId
  final String content;
  final String createdAt;
}

class MockOrderTimelineEvent {
  const MockOrderTimelineEvent({
    required this.event,
    required this.message,
    required this.createdAt,
  });

  final String event;
  final String message;
  final String createdAt;
}
