import '../core/constants.dart';

/// One row per order: escrow, platform fee, payout status. State machine: pending_payment → escrow_locked → … → completed.
class OrderFinanceModel {
  const OrderFinanceModel({
    required this.id,
    required this.orderId,
    required this.buyerPaidAmount,
    required this.platformFee,
    required this.escrowLocked,
    required this.creatorPayout,
    required this.payoutStatus,
    this.releasedAt,
    this.transactionId,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    required this.financeStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderFinanceModel.fromJson(Map<String, dynamic> json) {
    return OrderFinanceModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      buyerPaidAmount: (json['buyer_paid_amount'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      escrowLocked: json['escrow_locked'] as bool? ?? false,
      creatorPayout: (json['creator_payout'] as num?)?.toDouble() ?? 0,
      payoutStatus: json['payout_status'] as String? ?? 'pending',
      releasedAt: json['released_at'] != null ? DateTime.tryParse(json['released_at'] as String) : null,
      transactionId: json['transaction_id'] as String?,
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      razorpayOrderId: json['razorpay_order_id'] as String?,
      financeStatus: json['finance_status'] as String? ?? AppConstants.financePendingPayment,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String orderId;
  final double buyerPaidAmount;
  final double platformFee;
  final bool escrowLocked;
  final double creatorPayout;
  final String payoutStatus;
  final DateTime? releasedAt;
  final String? transactionId;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final String financeStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
}
