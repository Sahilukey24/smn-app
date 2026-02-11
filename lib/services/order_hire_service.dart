import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import 'escrow_service.dart';
import 'order_finance_service.dart';

/// Core hiring flow: create intent (pending_payment) → payment → onPaymentSuccess (escrow locked, in_progress, chat_room, timeline).
/// Uses EscrowService for order_contract + 12% platform / 88% creator.
class OrderHireService {
  OrderHireService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final OrderFinanceService _finance = OrderFinanceService(client);
  final EscrowService _escrow = EscrowService(client);

  /// Platform fee as % of price (contract: 12%).
  double platformFeeForPrice(double price) =>
      price * (AppConstants.contractPlatformFeePercent / 100);

  /// Create hiring intent: order, order_contract (12/88), order_finance, order_items. No chat_room yet.
  Future<String?> createHiringIntent({
    required String serviceId,
    required String buyerId,
    required double price,
  }) async {
    try {
      final service = await _client.from('services').select('id, name, profile_id, delivery_days').eq('id', serviceId).maybeSingle();
      if (service == null) return null;

      final profile = await _client.from('profiles').select('user_id').eq('id', service['profile_id']).maybeSingle();
      if (profile == null) return null;

      final providerId = profile['user_id'] as String;
      final profileId = service['profile_id'] as String;
      final serviceName = service['name'] as String;
      final totalInr = price;
      final platformFee = platformFeeForPrice(price);

      final orderRes = await _client.from('orders').insert({
        'buyer_id': buyerId,
        'provider_id': providerId,
        'profile_id': profileId,
        'service_id': serviceId,
        'total_inr': totalInr,
        'platform_charge_inr': platformFee,
        'status': AppConstants.orderPendingPayment,
        'updated_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final orderId = orderRes['id'] as String;

      await lockServiceSnapshot(
        orderId: orderId,
        serviceId: serviceId,
        serviceName: serviceName,
        priceInr: price,
        deliveryDays: (service['delivery_days'] as num?)?.toInt(),
      );

      await _escrow.createContract(
        orderId: orderId,
        buyerId: buyerId,
        creatorId: providerId,
        basePrice: totalInr,
      );

      await _addTimelineEntry(orderId, 'created', 'Order created', 'Awaiting payment');

      return orderId;
    } catch (_) {
      return null;
    }
  }

  /// Lock price & scope in order_items (snapshot).
  Future<void> lockServiceSnapshot({
    required String orderId,
    required String serviceId,
    required String serviceName,
    required double priceInr,
    int? deliveryDays,
  }) async {
    await _client.from('order_items').insert({
      'order_id': orderId,
      'service_id': serviceId,
      'service_name': serviceName,
      'price_inr': priceInr,
      'quantity': 1,
    });
  }

  /// Create chat_room between buyer and provider for this order.
  Future<bool> createChatRoom({
    required String orderId,
    required String buyerId,
    required String providerId,
  }) async {
    try {
      await _client.from('chat_rooms').insert({
        'order_id': orderId,
        'buyer_id': buyerId,
        'creator_id': providerId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Call after payment success: lock escrow + contract escrow_locked, in_progress, chat_room, timeline.
  Future<bool> onPaymentSuccess(String orderId, {String? razorpayPaymentId}) async {
    try {
      final order = await _client.from('orders').select('buyer_id, provider_id, status, total_inr, platform_charge_inr').eq('id', orderId).maybeSingle();
      if (order == null) return false;
      if (order['status'] != AppConstants.orderPendingPayment) return false;

      final buyerId = order['buyer_id'] as String;
      final providerId = order['provider_id'] as String;
      final totalInr = (order['total_inr'] as num).toDouble();
      final platformFee = (order['platform_charge_inr'] as num?)?.toDouble() ?? platformFeeForPrice(totalInr);
      final creatorPayout = totalInr - platformFee;

      final locked = await _finance.lockEscrow(
        orderId: orderId,
        razorpayPaymentId: razorpayPaymentId ?? 'sim_${orderId.substring(0, 8)}',
        transactionId: null,
        buyerPaidAmount: totalInr,
        platformFee: platformFee,
        creatorPayout: creatorPayout,
      );
      if (!locked) return false;

      await _escrow.onPaymentSuccess(orderId);

      await _client.from('orders').update({
        'chat_unlocked_at': DateTime.now().toIso8601String(),
        'ready_for_delivery_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      await createChatRoom(orderId: orderId, buyerId: buyerId, providerId: providerId);

      await _addTimelineEntry(orderId, 'payment_received', 'Payment received', 'Escrow locked. Order in progress.');

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _addTimelineEntry(String orderId, String eventType, String title, [String? description]) async {
    try {
      await _client.from('order_timeline').insert({
        'order_id': orderId,
        'event_type': eventType,
        'title': title,
        'description': description,
      });
    } catch (_) {}
  }

  /// Fetch order with items and timeline for dashboard.
  Future<Map<String, dynamic>?> getOrderWithTimeline(String orderId) async {
    try {
      final order = await _client.from('orders').select('*, order_items(*)').eq('id', orderId).maybeSingle();
      if (order == null) return null;
      final timeline = await _client.from('order_timeline').select().eq('order_id', orderId).order('created_at', ascending: true);
      (order as Map<String, dynamic>)['order_timeline'] = timeline;
      return order;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTimelineForOrder(String orderId) async {
    try {
      final res = await _client.from('order_timeline').select().eq('order_id', orderId).order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }
}
