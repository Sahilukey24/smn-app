import 'package:supabase_flutter/supabase_flutter.dart';

/// Order timeline: payment_received, work_started, delivered, revision, approved.
class OrderTimelineService {
  OrderTimelineService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> addEvent(
    String orderId,
    String eventType,
    String title, [
    String? description,
  ]) async {
    try {
      await _client.from('order_timeline').insert({
        'order_id': orderId,
        'event_type': eventType,
        'title': title,
        'description': description,
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getTimelineForOrder(String orderId) async {
    try {
      final res = await _client
          .from('order_timeline')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }
}
