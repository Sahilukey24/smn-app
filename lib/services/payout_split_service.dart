import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_contract_model.dart';

/// Payout split: after approval, create payout_splits (creator + optional freelancer) and release to profile balances.
class PayoutSplitService {
  PayoutSplitService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Create payout_splits for order from contract (creator 100% or creator/freelancer by invite %), then release (released_at + profile balance).
  Future<bool> createAndReleaseSplitsForOrder(
    String orderId,
    OrderContractModel contract,
  ) async {
    try {
      final totalCreatorPayout = contract.creatorPayout;
      if (contract.freelancerId != null && contract.freelancerId!.isNotEmpty) {
        final invite = await _client
            .from('order_freelancer_invites')
            .select('split_percent')
            .eq('order_id', orderId)
            .eq('freelancer_id', contract.freelancerId!)
            .eq('status', 'accepted')
            .maybeSingle();
        final freelancerPercent = (invite?['split_percent'] as num?)?.toDouble() ?? 0.0;
        final creatorPercent = 100.0 - freelancerPercent;
        final creatorAmount = totalCreatorPayout * (creatorPercent / 100);
        final freelancerAmount = totalCreatorPayout * (freelancerPercent / 100);

        await _client.from('payout_splits').insert([
          {
            'order_id': orderId,
            'user_id': contract.creatorId,
            'role': 'creator',
            'percent': creatorPercent,
            'amount_inr': creatorAmount,
            'released_at': DateTime.now().toIso8601String(),
          },
          {
            'order_id': orderId,
            'user_id': contract.freelancerId,
            'role': 'freelancer',
            'percent': freelancerPercent,
            'amount_inr': freelancerAmount,
            'released_at': DateTime.now().toIso8601String(),
          },
        ]);
        await _addToProfileBalance(contract.creatorId, creatorAmount);
        await _addToProfileBalance(contract.freelancerId!, freelancerAmount);
      } else {
        await _client.from('payout_splits').insert({
          'order_id': orderId,
          'user_id': contract.creatorId,
          'role': 'creator',
          'percent': 100.0,
          'amount_inr': totalCreatorPayout,
          'released_at': DateTime.now().toIso8601String(),
        });
        await _addToProfileBalance(contract.creatorId, totalCreatorPayout);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _addToProfileBalance(String userId, double amount) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (profile == null) return;
      final profileId = profile['id'] as String;
      try {
        await _client.rpc('increment_profile_balance', params: {
          'p_profile_id': profileId,
          'p_amount': amount,
        });
      } catch (_) {
        final cur = await _client
            .from('profiles')
            .select('balance_inr')
            .eq('id', profileId)
            .maybeSingle();
        final current = (cur?['balance_inr'] as num?)?.toDouble() ?? 0.0;
        await _client.from('profiles').update({
          'balance_inr': current + amount,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', profileId);
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getSplitsForOrder(String orderId) async {
    try {
      final res = await _client
          .from('payout_splits')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }
}
