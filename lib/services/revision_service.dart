import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../services/escrow_service.dart';
import '../services/fraud_detector.dart';
import '../services/order_timeline_service.dart';

/// Revisions: first 3 free, after that ₹50 per revision.
/// Table: order_revisions (id, order_id, user_id, reason, is_paid, amount, created_at).
/// FraudDetector.checkUnchanged can be triggered when a new delivery is uploaded for a revision.
class RevisionService {
  RevisionService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  String? get _userId => _client.auth.currentUser?.id;

  /// Number of revisions already created for this order (from order_revisions).
  Future<int> getRevisionCount(String orderId) async {
    try {
      final res = await _client.from('order_revisions').select('id').eq('order_id', orderId);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Check whether the requesting user has free revisions left for this order.
  /// Returns [FreeLimitResult] with remaining free count and whether next revision is paid.
  Future<FreeLimitResult> checkFreeLimit({required String userId, required String orderId}) async {
    final count = await getRevisionCount(orderId);
    final remainingFree = (AppConstants.freeRevisionsPerOrder - count).clamp(0, AppConstants.freeRevisionsPerOrder);
    final nextIsPaid = count >= AppConstants.freeRevisionsPerOrder;
    final nextAmountInr = nextIsPaid ? AppConstants.revisionFeeAfterFreeInr : 0.0;
    return FreeLimitResult(
      revisionCount: count,
      remainingFree: remainingFree,
      nextIsPaid: nextIsPaid,
      nextAmountInr: nextAmountInr,
    );
  }

  /// Request revision: create record in order_revisions, update order status and revision fields.
  /// Returns [RevisionResult] with success, amountInr, revisionNumber, status message.
  Future<RevisionResult> requestRevision({
    required String orderId,
    required String reason,
    String? deliveryId,
    bool fraudUnchanged = false,
  }) async {
    if (_userId == null) {
      return RevisionResult(success: false, amountInr: 0, revisionNumber: 0, status: 'not_authenticated');
    }
    final trimmed = reason.trim();
    if (trimmed.length < AppConstants.revisionReasonMinLength ||
        trimmed.length > AppConstants.revisionReasonMaxLength) {
      return RevisionResult(success: false, amountInr: 0, revisionNumber: 0, status: 'invalid_reason_length');
    }

    try {
      final count = await getRevisionCount(orderId);
      final revisionNumber = count + 1;
      final isPaid = count >= AppConstants.freeRevisionsPerOrder;
      final amountInr = isPaid ? AppConstants.revisionFeeAfterFreeInr : 0.0;

      await _client.from('order_revisions').insert({
        'order_id': orderId,
        'user_id': _userId!,
        'reason': trimmed,
        'is_paid': isPaid,
        'amount': amountInr,
      });

      final now = DateTime.now().toIso8601String();
      final orderRow = await _client.from('orders').select('revision_count, revision_paid').eq('id', orderId).single();
      final currentCount = (orderRow['revision_count'] as num?)?.toInt() ?? count;
      final currentPaid = (orderRow['revision_paid'] as num?)?.toDouble() ?? 0.0;

      await _client.from('orders').update({
        'status': AppConstants.orderRevision,
        'revision_count': currentCount + 1,
        'last_revision_at': now,
        'revision_paid': currentPaid + amountInr,
        'updated_at': now,
      }).eq('id', orderId);

      await EscrowService(_client).markRevisionRequested(orderId);
      await OrderTimelineService(_client).addEvent(orderId, 'revision_requested', 'Revision requested', 'Buyer requested revision #$revisionNumber.');

      if (fraudUnchanged) {
        await _applyUnchangedFileRefund(orderId, amountInr);
      }

      return RevisionResult(
        success: true,
        amountInr: amountInr,
        revisionNumber: revisionNumber,
        status: 'created',
      );
    } catch (e) {
      return RevisionResult(
        success: false,
        amountInr: 0,
        revisionNumber: 0,
        status: e.toString(),
      );
    }
  }

  /// Call when a new delivery file is uploaded (e.g. after a revision request).
  /// Runs FraudDetector.checkUnchanged. If result.isUnchanged, call requestRevision(..., fraudUnchanged: true)
  /// or apply refund/payout separately.
  Future<FraudCheckResult> triggerFraudCheckOnNewDelivery({
    required String orderId,
    required String deliveryId,
    required File newFile,
    required String fileType,
    String? previousDeliveryPath,
  }) async {
    final detector = FraudDetector(_client);
    return await detector.checkUnchanged(
      orderId: orderId,
      deliveryId: deliveryId,
      newFile: newFile,
      fileType: fileType,
      previousDeliveryPath: previousDeliveryPath,
    );
  }

  /// If unchanged file detected: refund buyer 50% + revision fees; creator payout 50% – platform.
  Future<void> _applyUnchangedFileRefund(String orderId, double revisionFeesInr) async {
    try {
      final order = await _client.from('orders').select('total_inr').eq('id', orderId).single();
      final totalInr = (order['total_inr'] as num).toDouble();
      final refundBuyer = totalInr * 0.5 + revisionFeesInr;
      await _client.from('payments').insert({
        'order_id': orderId,
        'user_id': _userId!,
        'amount_inr': -refundBuyer,
        'status': 'refunded',
      });
    } catch (_) {}
  }

  double getRevisionFeeInr() => AppConstants.revisionFeeAfterFreeInr;
  int getFreeRevisionsCount() => AppConstants.freeRevisionsPerOrder;
}

class FreeLimitResult {
  const FreeLimitResult({
    required this.revisionCount,
    required this.remainingFree,
    required this.nextIsPaid,
    required this.nextAmountInr,
  });
  final int revisionCount;
  final int remainingFree;
  final bool nextIsPaid;
  final double nextAmountInr;
}

class RevisionResult {
  const RevisionResult({
    required this.success,
    required this.amountInr,
    required this.revisionNumber,
    this.status = 'ok',
  });
  final bool success;
  final double amountInr;
  final int revisionNumber;
  final String status;
}
