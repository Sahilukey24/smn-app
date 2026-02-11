import '../core/constants.dart';

/// Smart hiring contract: scope, price, platform fee 12%, creator 88%, revisions, dispute window.
class OrderContractModel {
  const OrderContractModel({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.creatorId,
    this.freelancerId,
    required this.basePrice,
    required this.platformFee,
    required this.creatorPayout,
    required this.escrowLocked,
    required this.status,
    this.maxFreeRevisions = 3,
    this.paidRevisionPrice = 50,
    this.disputeWindowHours = 48,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderContractModel.fromJson(Map<String, dynamic> json) {
    return OrderContractModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      buyerId: json['buyer_id'] as String,
      creatorId: json['creator_id'] as String,
      freelancerId: json['freelancer_id'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      creatorPayout: (json['creator_payout'] as num).toDouble(),
      escrowLocked: json['escrow_locked'] as bool? ?? false,
      status: json['status'] as String? ?? AppConstants.contractPendingPayment,
      maxFreeRevisions: (json['max_free_revisions'] as num?)?.toInt() ?? AppConstants.freeRevisionsPerOrder,
      paidRevisionPrice: (json['paid_revision_price'] as num?)?.toDouble() ?? AppConstants.revisionFeeAfterFreeInr,
      disputeWindowHours: (json['dispute_window_hours'] as num?)?.toInt() ?? 48,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String orderId;
  final String buyerId;
  final String creatorId;
  final String? freelancerId;
  final double basePrice;
  final double platformFee;
  final double creatorPayout;
  final bool escrowLocked;
  final String status;
  final int maxFreeRevisions;
  final double paidRevisionPrice;
  final int disputeWindowHours;
  final DateTime createdAt;
  final DateTime updatedAt;
}
