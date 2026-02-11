import 'package:supabase_flutter/supabase_flutter.dart';

/// MVP order flow only: create order → payment (simulate) → delivered → approve → credit creator.
/// No escrow, revisions, disputes, Razorpay.
class MvpOrderService {
  MvpOrderService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const double _platformFeePercent = 12.0;

  double platformFeeForPrice(double price) => price * (_platformFeePercent / 100);

  /// Create order: buyer_id, creator_id (provider_id), service_id, price, status = pending_payment.
  /// Returns orderId or null.
  Future<String?> createOrder({
    required String buyerId,
    required String serviceId,
    required double price,
  }) async {
    try {
      final service = await _client
          .from('services')
          .select('id, name, profile_id, delivery_days')
          .eq('id', serviceId)
          .maybeSingle();
      if (service == null) return null;

      final profile = await _client
          .from('profiles')
          .select('user_id')
          .eq('id', service['profile_id'])
          .maybeSingle();
      if (profile == null) return null;

      final creatorId = profile['user_id'] as String;
      final profileId = service['profile_id'] as String;
      final serviceName = service['name'] as String;
      final platformFee = platformFeeForPrice(price);
      final totalInr = price;

      final orderRes = await _client.from('orders').insert({
        'buyer_id': buyerId,
        'provider_id': creatorId,
        'profile_id': profileId,
        'service_id': serviceId,
        'total_inr': totalInr,
        'platform_charge_inr': platformFee,
        'status': 'pending_payment',
        'updated_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final orderId = orderRes['id'] as String;

      await _client.from('order_items').insert({
        'order_id': orderId,
        'service_id': serviceId,
        'service_name': serviceName,
        'price_inr': totalInr,
        'quantity': 1,
      });

      return orderId;
    } catch (_) {
      return null;
    }
  }

  /// Simulate payment success: status = in_progress, create chat_room, unlock chat/delivery.
  Future<bool> markPaymentSuccess(String orderId) async {
    try {
      final order = await _client
          .from('orders')
          .select('buyer_id, provider_id, status')
          .eq('id', orderId)
          .maybeSingle();
      if (order == null || order['status'] != 'pending_payment') return false;

      final buyerId = order['buyer_id'] as String;
      final providerId = order['provider_id'] as String;

      await _client.from('orders').update({
        'status': 'in_progress',
        'chat_unlocked_at': DateTime.now().toIso8601String(),
        'ready_for_delivery_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      try {
        await _client.from('chat_rooms').insert({
          'order_id': orderId,
          'buyer_id': buyerId,
          'creator_id': providerId,
        });
      } catch (_) {}
      try {
        await _client.from('order_timeline').insert({
          'order_id': orderId,
          'event_type': 'payment_received',
          'title': 'Payment received',
          'description': 'Order in progress. Chat unlocked.',
        });
      } catch (_) {}

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Creator uploaded delivery: status = delivered, timeline event.
  Future<bool> markDelivered(String orderId) async {
    try {
      await _client.from('orders').update({
        'status': 'delivered',
        'delivered_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      try {
        await _client.from('order_timeline').insert({
          'order_id': orderId,
          'event_type': 'delivered',
          'title': 'Delivered',
          'description': 'Creator uploaded delivery.',
        });
      } catch (_) {}
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Buyer approved: status = completed, credit creator profile balance.
  Future<bool> approveOrder(String orderId) async {
    return approve(orderId);
  }

  Future<bool> approve(String orderId) async {
    try {
      final order = await _client
          .from('orders')
          .select('profile_id, total_inr, platform_charge_inr, status')
          .eq('id', orderId)
          .maybeSingle();
      if (order == null) return false;
      if (order['status'] != 'delivered') return false;

      final profileId = order['profile_id'] as String;
      final totalInr = (order['total_inr'] as num).toDouble();
      final platformCharge = (order['platform_charge_inr'] as num?)?.toDouble() ?? 0.0;
      final creatorPayout = totalInr - platformCharge;

      await _client.from('orders').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      try {
        await _client.rpc('increment_profile_balance', params: {
          'p_profile_id': profileId,
          'p_amount': creatorPayout,
        });
      } catch (_) {
        final cur = await _client
            .from('profiles')
            .select('balance_inr')
            .eq('id', profileId)
            .maybeSingle();
        final current = (cur?['balance_inr'] as num?)?.toDouble() ?? 0.0;
        await _client.from('profiles').update({
          'balance_inr': current + creatorPayout,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', profileId);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final res = await _client.from('orders').select('*').eq('id', orderId).maybeSingle();
      return res as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
