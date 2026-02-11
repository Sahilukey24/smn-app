import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors.dart';
import '../../models/order_model.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/order_repository.dart';
import 'cart_service.dart';

class OrderService {
  OrderService()
      : _client = Supabase.instance.client,
        _orderRepo = OrderRepository(Supabase.instance.client),
        _cartService = CartService();

  final SupabaseClient _client;
  final OrderRepository _orderRepo;
  final CartService _cartService;

  String? get _userId => _client.auth.currentUser?.id;

  /// Creates order from cart. Enforces deadline max 7 days. Use [CartService] for cart.
  Future<OrderModel?> createOrderFromCart({
    required String profileId,
    required DateTime proposedDeadline,
  }) async {
    final cartRepo = CartRepository(_client);
    try {
      return await _orderRepo.createOrderFromCart(
        profileId: profileId,
        proposedDeadline: proposedDeadline,
        cartRepo: cartRepo,
      );
    } on DeadlineExceedsMaxException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<OrderModel?> getOrder(String orderId) => _orderRepo.getOrder(orderId);

  Future<bool> acceptDeadline(String orderId, DateTime acceptedDeadline) =>
      _orderRepo.acceptDeadline(orderId, acceptedDeadline);

  /// Max 2 counter proposals. Deadline max 7 days.
  Future<bool> proposeNewDeadline(String orderId, DateTime proposedDeadline) async {
    try {
      return await _orderRepo.proposeNewDeadline(orderId, proposedDeadline);
    } on CounterProposalsExceededException {
      rethrow;
    } on DeadlineExceedsMaxException {
      rethrow;
    }
    return false;
  }

  Future<bool> markReadyForDelivery(String orderId) =>
      _orderRepo.markReadyForDelivery(orderId);

  Future<List<OrderModel>> getMyOrders({String? status}) =>
      _orderRepo.getMyOrders(status: status);
}
