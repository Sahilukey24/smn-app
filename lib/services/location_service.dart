import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_location_model.dart';

/// Location share: WhatsApp-style pin only. No address typing. Table: order_locations.
class LocationService {
  LocationService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  String? get _userId => _client.auth.currentUser?.id;

  /// Share location (pin) for an order.
  Future<OrderLocationModel?> shareLocation({
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    if (_userId == null) return null;
    try {
      final res = await _client.from('order_locations').insert({
        'order_id': orderId,
        'lat': lat,
        'lng': lng,
        'shared_by': _userId!,
      }).select().single();
      return OrderLocationModel.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<OrderLocationModel>> getLocationsForOrder(String orderId) async {
    try {
      final res = await _client.from('order_locations').select().eq('order_id', orderId).order('created_at', ascending: false);
      return (res as List).map((e) => OrderLocationModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
