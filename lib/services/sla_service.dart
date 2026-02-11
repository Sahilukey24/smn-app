import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/order_model.dart';
import '../models/penalty_model.dart';

/// SLA: penalty (2%/day, max 10%, grace 6h), auto-complete (48h after delivery), 48h auto-cancel before accept.
/// Run penalty calculation and auto-complete/cancel from a cron or Edge Function in production.
class SlaService {
  SlaService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Compute penalty for late delivery: grace 6h, then 2% per day, max 10%.
  static double computePenaltyPercent(DateTime acceptedDeadline, DateTime actualDelivery) {
    const graceHours = AppConstants.penaltyGraceHours;
    final graceEnd = acceptedDeadline.add(Duration(hours: graceHours));
    if (actualDelivery.isBefore(graceEnd) || actualDelivery.isAtSameMomentAs(graceEnd)) return 0;
    final late = actualDelivery.difference(graceEnd);
    final daysLate = late.inDays + (late.inHours > 0 ? 1 : 0);
    final percent = (daysLate * AppConstants.penaltyPercentPerDay).clamp(0.0, AppConstants.penaltyMaxPercent);
    return percent;
  }

  static double computePenaltyAmount(double orderTotalInr, double penaltyPercent) {
    return orderTotalInr * (penaltyPercent / 100);
  }

  /// Record penalty for an order (call when delivery is late).
  Future<PenaltyModel?> recordPenalty({
    required String orderId,
    required DateTime acceptedDeadline,
    required DateTime deliveredAt,
    required double orderTotalInr,
  }) async {
    final percent = computePenaltyPercent(acceptedDeadline, deliveredAt);
    if (percent == 0) return null;
    final amount = computePenaltyAmount(orderTotalInr, percent);
    final graceEnd = acceptedDeadline.add(const Duration(hours: AppConstants.penaltyGraceHours));
    final daysLate = deliveredAt.difference(graceEnd).inDays + 1;

    final res = await _client.from('penalties').insert({
      'order_id': orderId,
      'penalty_percent': percent,
      'penalty_amount_inr': amount,
      'days_late': daysLate,
      'grace_applied': true,
    }).select().single();

    return PenaltyModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<PenaltyModel>> getPenaltiesForOrder(String orderId) async {
    final res = await _client.from('penalties').select().eq('order_id', orderId);
    return (res as List).map((e) => PenaltyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Check if order should auto-cancel: pending and last_proposal_at > 48h ago.
  Future<bool> shouldAutoCancelOrder(OrderModel order) async {
    if (order.status != AppConstants.orderPending) return false;
    final last = order.lastProposalAt ?? order.createdAt;
    return DateTime.now().difference(last).inHours >= AppConstants.pendingResponseHours;
  }

  /// Check if delivered order should auto-complete: delivered_at + 48h passed.
  Future<bool> shouldAutoCompleteOrder(OrderModel order) async {
    if (order.status != AppConstants.orderDelivered) return false;
    final deliveredAt = order.deliveredAt;
    if (deliveredAt == null) return false;
    return DateTime.now().difference(deliveredAt).inHours >= AppConstants.autoCompleteHoursAfterDelivery;
  }

  /// Mark order as delivered (provider). Auto-complete runs separately (cron).
  Future<bool> markOrderDelivered(String orderId) async {
    try {
      await _client.from('orders').update({
        'status': AppConstants.orderDelivered,
        'delivered_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Auto-complete order (call from cron/Edge).
  Future<bool> autoCompleteOrder(String orderId) async {
    try {
      await _client.from('orders').update({
        'status': AppConstants.orderCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId).eq('status', AppConstants.orderDelivered);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Auto-cancel pending order (call from cron/Edge).
  Future<bool> autoCancelOrder(String orderId) async {
    try {
      await _client.from('orders').update({
        'status': AppConstants.orderCancelled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId).eq('status', AppConstants.orderPending);
      return true;
    } catch (_) {
      return false;
    }
  }
}
