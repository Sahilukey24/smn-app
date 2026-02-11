import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/dispute_model.dart';

class DisputeRepository {
  DisputeRepository(this._client);
  final SupabaseClient _client;

  Future<DisputeModel?> getByOrderId(String orderId) async {
    try {
      final res = await _client.from('disputes').select().eq('order_id', orderId).maybeSingle();
      return res != null ? DisputeModel.fromJson(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<DisputeModel?> create({required String orderId, required String reason}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final res = await _client.from('disputes').insert({
        'order_id': orderId,
        'raised_by': userId,
        'reason': reason,
        'status': AppConstants.disputeOpen,
      }).select().single();
      return DisputeModel.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<DisputeModel>> getMyDisputes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final orders = await _client.from('orders').select('id').or('buyer_id.eq.$userId,provider_id.eq.$userId');
      final orderIds = (orders as List).map((e) => (e as Map)['id'] as String).toList();
      if (orderIds.isEmpty) return [];
      final res = await _client.from('disputes').select().inFilter('order_id', orderIds).order('created_at', ascending: false);
      return (res as List).map((e) => DisputeModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
