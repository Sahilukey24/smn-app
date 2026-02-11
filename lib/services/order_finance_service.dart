import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/order_finance_model.dart';

/// Escrow payment: order_finance state machine, Razorpay integration hooks.
/// State: PENDING_PAYMENT → ESCROW_LOCKED → DELIVERED → APPROVED → PAYOUT_RELEASED → COMPLETED.
class OrderFinanceService {
  OrderFinanceService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Platform fee for an order (fixed per order).
  double calculatePlatformFee({double? orderAmount}) =>
      AppConstants.platformChargePerOrderInr;

  /// Create order_finance row when order is created (pending_payment). Call from createHiringIntent.
  Future<bool> createFinanceRow({
    required String orderId,
    required double buyerPaidAmount,
    required double platformFee,
    String? razorpayOrderId,
  }) async {
    try {
      await _client.from('order_finance').insert({
        'order_id': orderId,
        'buyer_paid_amount': buyerPaidAmount,
        'platform_fee': platformFee,
        'escrow_locked': false,
        'creator_payout': 0,
        'payout_status': 'pending',
        'finance_status': AppConstants.financePendingPayment,
        'razorpay_order_id': razorpayOrderId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// payment.captured → lock escrow, set order in_progress.
  Future<bool> lockEscrow({
    required String orderId,
    required String razorpayPaymentId,
    String? transactionId,
    required double buyerPaidAmount,
    required double platformFee,
    required double creatorPayout,
  }) async {
    try {
      final order = await _client.from('orders').select('status').eq('id', orderId).maybeSingle();
      if (order == null || order['status'] != AppConstants.orderPendingPayment) return false;

      await _client.from('order_finance').update({
        'buyer_paid_amount': buyerPaidAmount,
        'platform_fee': platformFee,
        'escrow_locked': true,
        'creator_payout': creatorPayout,
        'razorpay_payment_id': razorpayPaymentId,
        'transaction_id': transactionId,
        'finance_status': AppConstants.financeEscrowLocked,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);

      await _client.from('orders').update({
        'status': AppConstants.orderInProgress,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark order delivered (finance_status → delivered). Call when creator uploads delivery.
  Future<bool> markDelivered(String orderId) async {
    try {
      await _client.from('order_finance').update({
        'finance_status': AppConstants.financeDelivered,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Buyer approved → order status approved, finance_status approved. Payout still pending.
  Future<bool> markApproved(String orderId) async {
    try {
      await _client.from('orders').update({
        'status': AppConstants.orderApproved,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      await _client.from('order_finance').update({
        'finance_status': AppConstants.financeApproved,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// payout.processed → release payout, set payout_status released, finance_status payout_released.
  Future<bool> releasePayout({
    required String orderId,
    String? transactionId,
  }) async {
    try {
      await _client.from('order_finance').update({
        'payout_status': 'released',
        'released_at': DateTime.now().toIso8601String(),
        'transaction_id': transactionId,
        'finance_status': AppConstants.financePayoutReleased,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark order and finance completed (after payout released + optional hold period).
  Future<bool> markCompleted(String orderId) async {
    try {
      await _client.from('order_finance').update({
        'finance_status': AppConstants.financeCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      await _client.from('orders').update({
        'status': AppConstants.orderCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Buyer approved: mark approved → release payout (simulated) → mark completed, add creator balance.
  Future<bool> approveAndComplete(String orderId) async {
    try {
      final fin = await getFinanceForOrder(orderId);
      if (fin == null || !fin.escrowLocked) return false;
      final order = await _client.from('orders').select('profile_id').eq('id', orderId).maybeSingle();
      if (order == null) return false;
      final profileId = order['profile_id'] as String;
      final creatorPayout = fin.creatorPayout;

      await markApproved(orderId);
      await releasePayout(orderId: orderId, transactionId: 'payout_$orderId');
      await markCompleted(orderId);

      try {
        await _client.rpc('increment_profile_balance', params: {
          'p_profile_id': profileId,
          'p_amount': creatorPayout,
        });
      } catch (_) {
        final cur = await _client.from('profiles').select('balance_inr').eq('id', profileId).maybeSingle();
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

  /// payment.failed → cancel order, set order failed.
  Future<bool> cancelOrderOnPaymentFailed(String orderId) async {
    try {
      await _client.from('orders').update({
        'status': AppConstants.orderFailed,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      await _client.from('order_finance').update({
        'finance_status': AppConstants.financePendingPayment,
        'payout_status': 'failed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// refund.processed → reverse: update finance payout_status refunded, order status as needed.
  Future<bool> refundBuyer({
    required String orderId,
    required double refundAmount,
    String? transactionId,
  }) async {
    try {
      await _client.from('order_finance').update({
        'payout_status': 'refunded',
        'transaction_id': transactionId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('order_id', orderId);
      await _client.from('orders').update({
        'status': AppConstants.orderCancelled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<OrderFinanceModel?> getFinanceForOrder(String orderId) async {
    try {
      final res = await _client.from('order_finance').select().eq('order_id', orderId).maybeSingle();
      return res != null ? OrderFinanceModel.fromJson(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }
}
