import '../../models/mock_order.dart';

/// In-memory store for MockOrder and balances. No backend.
class MockOrderStore {
  MockOrderStore._();
  static final MockOrderStore instance = MockOrderStore._();

  final List<MockOrder> _orders = [];
  final Map<String, double> _creatorBalance = {};
  double _platformBalance = 0;

  List<MockOrder> get orders => List.unmodifiable(_orders);
  double get platformBalance => _platformBalance;
  double creatorBalance(String creatorId) => _creatorBalance[creatorId] ?? 0;

  MockOrder? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  List<MockOrder> getOrdersForBuyer(String buyerId) {
    return _orders.where((o) => o.buyerId == buyerId).toList();
  }

  List<MockOrder> getOrdersForCreator(String creatorId) {
    return _orders.where((o) => o.creatorId == creatorId).toList();
  }

  MockOrder createOrder({
    required String serviceName,
    required String creatorName,
    required String creatorId,
    required double price,
    double platformFee = 15,
    String buyerId = 'business-1',
  }) {
    final order = MockOrder(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      serviceName: serviceName,
      creatorName: creatorName,
      creatorId: creatorId,
      price: price,
      platformFee: platformFee,
      status: 'pending_payment',
      buyerId: buyerId,
      timeline: [
        MockOrderTimelineEvent(
          event: 'created',
          message: 'Order created. Awaiting payment.',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ],
    );
    _orders.add(order);
    return order;
  }

  void updateOrder(String orderId, MockOrder Function(MockOrder) update) {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) _orders[i] = update(_orders[i]);
  }

  void addMessage(String orderId, String senderId, String content) {
    updateOrder(orderId, (o) {
      final msg = MockOrderMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        content: content,
        createdAt: DateTime.now().toIso8601String(),
      );
      return o.copyWith(messages: [...o.messages, msg]);
    });
  }

  void addTimelineEvent(String orderId, String event, String message) {
    updateOrder(orderId, (o) {
      final ev = MockOrderTimelineEvent(
        event: event,
        message: message,
        createdAt: DateTime.now().toIso8601String(),
      );
      return o.copyWith(timeline: [...o.timeline, ev]);
    });
  }

  void markDelivered(String orderId, String fileLabel) {
    updateOrder(orderId, (o) => o.copyWith(
      status: 'delivered',
      deliveredFile: fileLabel,
    ));
    addTimelineEvent(orderId, 'delivered', 'Creator uploaded delivery.');
  }

  void approveOrder(String orderId) {
    final order = getOrderById(orderId);
    if (order == null || order.status != 'delivered') return;
    updateOrder(orderId, (o) => o.copyWith(status: 'completed'));
    _creatorBalance[order.creatorId] = (_creatorBalance[order.creatorId] ?? 0) + order.price;
    _platformBalance += order.platformFee;
    addTimelineEvent(orderId, 'approved', 'Order approved. Creator earnings updated.');
  }
}
