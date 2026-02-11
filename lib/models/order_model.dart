import '../core/constants.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.buyerId,
    required this.providerId,
    required this.profileId,
    required this.status,
    this.proposedDeadline,
    this.acceptedDeadline,
    required this.totalInr,
    this.platformChargeInr = 49,
    this.chatUnlockedAt,
    this.readyForDeliveryAt,
    this.counterProposals = 0,
    this.payoutFrozen = false,
    this.lastProposalAt,
    this.deliveredAt,
    required this.createdAt,
    this.items = const [],
    this.scheduledDate,
    this.startTime,
    this.durationMinutes,
    this.acceptedScheduledDate,
    this.acceptedStartTime,
    this.acceptedDurationMinutes,
    this.revisionCount = 0,
    this.lastRevisionAt,
    this.revisionPaid = 0,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      providerId: json['provider_id'] as String,
      profileId: json['profile_id'] as String,
      status: json['status'] as String? ?? AppConstants.orderPending,
      proposedDeadline: json['proposed_deadline'] != null
          ? DateTime.tryParse(json['proposed_deadline'] as String)
          : null,
      acceptedDeadline: json['accepted_deadline'] != null
          ? DateTime.tryParse(json['accepted_deadline'] as String)
          : null,
      totalInr: (json['total_inr'] as num).toDouble(),
      platformChargeInr: (json['platform_charge_inr'] as num?)?.toDouble() ?? 49,
      chatUnlockedAt: json['chat_unlocked_at'] != null
          ? DateTime.tryParse(json['chat_unlocked_at'] as String)
          : null,
      readyForDeliveryAt: json['ready_for_delivery_at'] != null
          ? DateTime.tryParse(json['ready_for_delivery_at'] as String)
          : null,
      counterProposals: (json['counter_proposals'] as num?)?.toInt() ?? 0,
      payoutFrozen: json['payout_frozen'] as bool? ?? false,
      lastProposalAt: json['last_proposal_at'] != null
          ? DateTime.tryParse(json['last_proposal_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      items: (json['order_items'] as List?)?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      scheduledDate: json['scheduled_date'] != null ? DateTime.tryParse(json['scheduled_date'] as String) : null,
      startTime: _parseTime(json['start_time']),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      acceptedScheduledDate: json['accepted_scheduled_date'] != null ? DateTime.tryParse(json['accepted_scheduled_date'] as String) : null,
      acceptedStartTime: _parseTime(json['accepted_start_time']),
      acceptedDurationMinutes: (json['accepted_duration_minutes'] as num?)?.toInt(),
      revisionCount: (json['revision_count'] as num?)?.toInt() ?? 0,
      lastRevisionAt: json['last_revision_at'] != null ? DateTime.tryParse(json['last_revision_at'] as String) : null,
      revisionPaid: (json['revision_paid'] as num?)?.toDouble() ?? 0,
    );
  }

  static Duration? _parseTime(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final parts = v.split(':');
      final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return Duration(hours: h, minutes: m);
    }
    return null;
  }

  final String id;
  final String buyerId;
  final String providerId;
  final String profileId;
  final String status;
  final DateTime? proposedDeadline;
  final DateTime? acceptedDeadline;
  final double totalInr;
  final double platformChargeInr;
  final DateTime? chatUnlockedAt;
  final DateTime? readyForDeliveryAt;
  final int counterProposals;
  final bool payoutFrozen;
  final DateTime? lastProposalAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final DateTime? scheduledDate;
  final Duration? startTime;
  final int? durationMinutes;
  final DateTime? acceptedScheduledDate;
  final Duration? acceptedStartTime;
  final int? acceptedDurationMinutes;
  final int revisionCount;
  final DateTime? lastRevisionAt;
  final double revisionPaid;

  bool get isChatUnlocked => chatUnlockedAt != null;
  bool get canUploadDelivery => readyForDeliveryAt != null;
}


class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.priceInr,
    this.quantity = 1,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      serviceName: json['service_name'] as String,
      priceInr: (json['price_inr'] as num).toDouble(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  final String id;
  final String serviceId;
  final String serviceName;
  final double priceInr;
  final int quantity;
}
