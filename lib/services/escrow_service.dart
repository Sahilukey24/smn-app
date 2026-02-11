import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/order_contract_model.dart';
import 'order_finance_service.dart';
import 'order_timeline_service.dart';
import 'payout_split_service.dart';

/// Smart hiring contract + escrow: create contract on hire (12% / 88%), lock on payment, release + split on approve.
class EscrowService {
  EscrowService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client,
        _finance = OrderFinanceService(client),
        _timeline = OrderTimelineService(client),
        _payoutSplit = PayoutSplitService(client);

  final SupabaseClient _client;
  final OrderFinanceService _finance;
  final OrderTimelineService _timeline;
  final PayoutSplitService _payoutSplit;

  /// Contract platform fee 12%, creator 88% of base (total buyer pays).
  double platformFeePercent(num basePrice) =>
      (basePrice * (AppConstants.contractPlatformFeePercent / 100));
  double creatorPayoutFromBase(num basePrice) =>
      (basePrice * (AppConstants.contractCreatorSharePercent / 100));

  /// On HIRE: create order_contract (scope + price + fees), create order_finance row with same 12/88 split.
  /// [basePrice] = total amount buyer will pay (order total_inr). Contract stores platform_fee = 12%, creator_payout = 88%.
  Future<OrderContractModel?> createContract({
    required String orderId,
    required String buyerId,
    required String creatorId,
    required double basePrice,
    String? freelancerId,
  }) async {
    try {
      final platformFee = platformFeePercent(basePrice);
      final creatorPayout = creatorPayoutFromBase(basePrice);

      await _client.from('order_contracts').insert({
        'order_id': orderId,
        'buyer_id': buyerId,
        'creator_id': creatorId,
        'freelancer_id': freelancerId,
        'base_price': basePrice,
        'platform_fee': platformFee,
        'creator_payout': creatorPayout,
        'escrow_locked': false,
        'status': AppConstants.contractPendingPayment,
        'max_free_revisions': AppConstants.freeRevisionsPerOrder,
        'paid_revision_price': AppConstants.revisionFeeAfterFreeInr,
        'dispute_window_hours': AppConstants.contractDisputeWindowHours,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _finance.createFinanceRow(
        orderId: orderId,
        buyerPaidAmount: basePrice,
        platformFee: platformFee,
        creatorPayout: creatorPayout,
      );

      return getContractForOrder(orderId);
    } catch (_) {
      return null;
    }
  }

  /// Payment success: set contract status = escrow_locked, update contract.escrow_locked. Finance lock is done by OrderHireService.
  Future<bool> onPaymentSuccess(String orderId) async {
    try {
      await _client.from('order_contracts').update({
        'escrow_locked': true,
        'status': AppConstants.contractEscrowLocked,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark contract in_progress (work started).
  Future<bool> markInProgress(String orderId) async {
    try {
      await _client.from('order_contracts').update({
        'status': AppConstants.contractInProgress,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark contract delivered.
  Future<bool> markDelivered(String orderId) async {
    try {
      await _client.from('order_contracts').update({
        'status': AppConstants.contractDelivered,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark revision requested.
  Future<bool> markRevisionRequested(String orderId) async {
    try {
      await _client.from('order_contracts').update({
        'status': AppConstants.contractRevisionRequested,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Buyer approved: contract → approved, then payout release + split platform/creator/freelancer, then completed.
  Future<bool> onApprove(String orderId) async {
    try {
      final contract = await getContractForOrder(orderId);
      if (contract == null || !contract.escrowLocked) return false;

      await _client.from('order_contracts').update({
        'status': AppConstants.contractApproved,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);

      await _finance.markApproved(orderId);

      await _payoutSplit.createAndReleaseSplitsForOrder(orderId, contract);
      await _finance.releasePayout(orderId: orderId, transactionId: 'payout_$orderId');
      await _finance.markCompleted(orderId);

      await _client.from('order_contracts').update({
        'status': AppConstants.contractPayoutReleased,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);

      await _client.from('order_contracts').update({
        'status': AppConstants.contractCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);

      await _timeline.addEvent(orderId, 'approved', 'Order approved', 'Payout released.');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<OrderContractModel?> getContractForOrder(String orderId) async {
    try {
      final res = await _client
          .from('order_contracts')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();
      return res != null
          ? OrderContractModel.fromJson(res as Map<String, dynamic>)
          : null;
    } catch (_) {
      return null;
    }
  }
}
