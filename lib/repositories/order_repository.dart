import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/errors.dart';
import '../models/order_model.dart';
import 'cart_repository.dart';

class OrderRepository {
  OrderRepository(this._client);
  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Deadline must be <= 7 days from now.
  Future<OrderModel?> createOrderFromCart({
    required String profileId,
    required DateTime proposedDeadline,
    required CartRepository cartRepo,
  }) async {
    if (_userId == null) return null;
    final now = DateTime.now();
    final maxDeadline = now.add(Duration(days: AppConstants.deadlineMaxDays));
    if (proposedDeadline.isAfter(maxDeadline)) {
      throw DeadlineExceedsMaxException(AppConstants.deadlineMaxDays);
    }
    final items = await cartRepo.getCartItems();
    if (items.isEmpty) return null;
    final profileIds = items.map((e) => e.service.profileId).toSet();
    if (profileIds.length != 1 || profileIds.first != profileId) return null;

    try {
      final profileRow = await _client.from('profiles').select('user_id').eq('id', profileId).single();
      final providerId = profileRow['user_id'] as String;
      final totalServices = items.fold<double>(0, (a, b) => a + b.service.priceInr * b.quantity);
      final totalInr = totalServices + AppConstants.platformChargePerOrderInr;

      final orderRes = await _client.from('orders').insert({
        'buyer_id': _userId!,
        'provider_id': providerId,
        'profile_id': profileId,
        'status': AppConstants.orderPending,
        'proposed_deadline': proposedDeadline.toIso8601String(),
        'last_proposal_at': now.toIso8601String(),
        'total_inr': totalInr,
        'platform_charge_inr': AppConstants.platformChargePerOrderInr,
      }).select().single();
      final orderId = orderRes['id'] as String;

      for (final item in items) {
        await _client.from('order_items').insert({
          'order_id': orderId,
          'service_id': item.service.id,
          'service_name': item.service.name,
          'price_inr': item.service.priceInr,
          'quantity': item.quantity,
        });
      }
      await cartRepo.clearCart();
      return OrderModel.fromJson(orderRes as Map<String, dynamic>);
    } catch (e) {
      if (e is DeadlineExceedsMaxException) rethrow;
      return null;
    }
  }

  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final res = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .maybeSingle();
      return res != null ? OrderModel.fromJson(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  /// Provider accepts deadline. Chat unlocks.
  Future<bool> acceptDeadline(String orderId, DateTime acceptedDeadline) async {
    try {
      await _client.from('orders').update({
        'status': AppConstants.orderInProgress,
        'accepted_deadline': acceptedDeadline.toIso8601String(),
        'chat_unlocked_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Provider proposes new deadline. Max 2 counter proposals.
  Future<bool> proposeNewDeadline(String orderId, DateTime proposedDeadline) async {
    final order = await getOrder(orderId);
    if (order == null || order.counterProposals >= AppConstants.counterProposalsMax) {
      throw CounterProposalsExceededException();
    }
    final now = DateTime.now();
    final maxDeadline = now.add(const Duration(days: AppConstants.deadlineMaxDays));
    if (proposedDeadline.isAfter(maxDeadline)) {
      throw DeadlineExceedsMaxException(AppConstants.deadlineMaxDays);
    }
    try {
      await _client.from('orders').update({
        'proposed_deadline': proposedDeadline.toIso8601String(),
        'counter_proposals': order.counterProposals + 1,
        'last_proposal_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', orderId);
      return true;
    } catch (_) {
      rethrow;
    }
  }

  /// Creator marks "Ready for Delivery" → file upload unlocked for provider.
  Future<bool> markReadyForDelivery(String orderId) async {
    try {
      await _client.from('orders').update({
        'ready_for_delivery_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId).eq('status', AppConstants.orderInProgress);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<OrderModel>> getMyOrders({String? status}) async {
    if (_userId == null) return [];
    try {
      var q = _client.from('orders').select('*, order_items(*)').or('buyer_id.eq.$_userId,provider_id.eq.$_userId');
      if (status != null) q = q.eq('status', status);
      final res = await q.order('created_at', ascending: false);
      return (res as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
