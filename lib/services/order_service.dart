import 'package:supabase_flutter/supabase_flutter.dart';

/// Core order money flow: createOrder(serviceId, buyerId, price), mark delivered, mark completed.
/// Tables: orders (id, service_id, buyer_id, creator_id via provider_id, price, status), chat_rooms.
class OrderService {
  OrderService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Create order: insert order, order_item, and chat_room. status = 'pending'.
  /// Returns order id or null.
  Future<String?> createOrder({
    required String serviceId,
    required String buyerId,
    required double price,
  }) async {
    try {
      final service = await _client.from('services').select('id, name, profile_id').eq('id', serviceId).maybeSingle();
      if (service == null) return null;

      final profile = await _client.from('profiles').select('user_id').eq('id', service['profile_id']).maybeSingle();
      if (profile == null) return null;

      final creatorId = profile['user_id'] as String;
      final profileId = service['profile_id'] as String;
      final serviceName = service['name'] as String;

      final orderRes = await _client.from('orders').insert({
        'buyer_id': buyerId,
        'provider_id': creatorId,
        'profile_id': profileId,
        'service_id': serviceId,
        'total_inr': price,
        'status': 'pending',
        'platform_charge_inr': 0,
        'ready_for_delivery_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final orderId = orderRes['id'] as String;

      await _client.from('order_items').insert({
        'order_id': orderId,
        'service_id': serviceId,
        'service_name': serviceName,
        'price_inr': price,
        'quantity': 1,
      });

      await _client.from('chat_rooms').insert({
        'order_id': orderId,
        'buyer_id': buyerId,
        'creator_id': creatorId,
      });

      return orderId;
    } catch (_) {
      return null;
    }
  }

  /// Mark order status = 'delivered'. Call after creator uploads delivery.
  Future<bool> markDelivered(String orderId) async {
    try {
      await _client.from('orders').update({
        'status': 'delivered',
        'delivered_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark order status = 'completed' and add earnings to creator balance.
  Future<bool> markCompleted(String orderId) async {
    try {
      final order = await _client.from('orders').select('profile_id, total_inr').eq('id', orderId).maybeSingle();
      if (order == null) return false;

      final profileId = order['profile_id'] as String;
      final totalInr = (order['total_inr'] as num).toDouble();

      await _client.from('orders').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      await _client.rpc('increment_profile_balance', params: {
        'p_profile_id': profileId,
        'p_amount': totalInr,
      });
      return true;
    } catch (_) {
      final order = await _client.from('orders').select('profile_id, total_inr').eq('id', orderId).maybeSingle();
      if (order == null) return false;
      final profileId = order['profile_id'] as String;
      final totalInr = (order['total_inr'] as num).toDouble();
      final cur = await _client.from('profiles').select('balance_inr').eq('id', profileId).maybeSingle();
      final current = (cur?['balance_inr'] as num?)?.toDouble() ?? 0.0;
      await _client.from('profiles').update({
        'balance_inr': current + totalInr,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', profileId);
      return true;
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
