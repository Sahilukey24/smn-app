import '../../data/mock/mock_order_store.dart';

/// Mock earnings: on approve, creator_balance += service_price, platform_balance += 15.
class MockEarningsService {
  MockEarningsService._();
  static final MockEarningsService instance = MockEarningsService._();

  final _store = MockOrderStore.instance;

  /// Call after buyer approves. Updates in-memory balances.
  void onApprove(String orderId) {
    _store.approveOrder(orderId);
  }

  double get creatorBalance(String creatorId) => _store.creatorBalance(creatorId);
  double get platformBalance => _store.platformBalance;
}
