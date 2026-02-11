import 'mock_models.dart';

/// In-memory mock data for product-first flow. No backend.
class MockRepository {
  MockRepository._();
  static final MockRepository instance = MockRepository._();

  final List<MockServiceModel> _services = [
    const MockServiceModel(
      id: 'svc-1',
      title: 'Video Edit - 1 min',
      price: 499,
      creatorId: 'creator-1',
      description: 'Professional 1-minute video edit with cuts, music, and captions.',
      creatorName: 'Rahul',
      rating: 4.8,
      deliveryDays: 3,
    ),
    const MockServiceModel(
      id: 'svc-2',
      title: 'Social Media Reel',
      price: 799,
      creatorId: 'creator-1',
      description: 'Instagram/YouTube reel with trending audio and transitions.',
      creatorName: 'Rahul',
      rating: 4.8,
      deliveryDays: 5,
    ),
    const MockServiceModel(
      id: 'svc-3',
      title: 'Thumbnail Design',
      price: 299,
      creatorId: 'creator-2',
      description: 'Custom YouTube thumbnail with text and graphics.',
      creatorName: 'Priya',
      rating: 4.5,
      deliveryDays: 2,
    ),
  ];

  final List<MockOrderModel> _orders = [];
  final Map<String, List<Map<String, dynamic>>> _messages = {};
  final Map<String, List<Map<String, dynamic>>> _deliveries = {};
  final Map<String, List<Map<String, dynamic>>> _timeline = {};
  final Map<String, double> _earnings = {}; // creatorId -> balance

  List<MockServiceModel> getServices() => List.unmodifiable(_services);

  MockServiceModel? getServiceById(String id) {
    try {
      return _services.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  MockOrderModel? createOrder({
    required String serviceId,
    required String buyerId,
    required String creatorId,
    required double price,
  }) {
    final order = MockOrderModel(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      serviceId: serviceId,
      buyerId: buyerId,
      creatorId: creatorId,
      price: price,
      status: 'pending_payment',
      createdAt: DateTime.now(),
    );
    _orders.add(order);
    return order;
  }

  MockOrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateOrderStatus(String orderId, String status) {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) {
      _orders[i] = _orders[i].copyWith(status: status);
    }
  }

  List<MockOrderModel> getOrdersForUser(String userId) {
    return _orders.where((o) => o.buyerId == userId || o.creatorId == userId).toList();
  }

  List<Map<String, dynamic>> getMessages(String orderId) {
    return List.unmodifiable(_messages[orderId] ?? []);
  }

  void sendMessage(String orderId, String senderId, String content) {
    _messages.putIfAbsent(orderId, () => []);
    _messages[orderId]!.add({
      'id': 'msg-${DateTime.now().millisecondsSinceEpoch}',
      'sender_id': senderId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> getDeliveries(String orderId) {
    return List.unmodifiable(_deliveries[orderId] ?? []);
  }

  void addDelivery(String orderId, String fileLabel) {
    _deliveries.putIfAbsent(orderId, () => []);
    _deliveries[orderId]!.add({
      'id': 'del-${DateTime.now().millisecondsSinceEpoch}',
      'file_url': fileLabel,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> getTimeline(String orderId) {
    return List.unmodifiable(_timeline[orderId] ?? []);
  }

  void addTimelineEvent(String orderId, String event, String message) {
    _timeline.putIfAbsent(orderId, () => []);
    _timeline[orderId]!.add({
      'event': event,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  double getCreatorEarnings(String creatorId) => _earnings[creatorId] ?? 0;

  void addToCreatorEarnings(String creatorId, double amount) {
    _earnings[creatorId] = (_earnings[creatorId] ?? 0) + amount;
  }
}
