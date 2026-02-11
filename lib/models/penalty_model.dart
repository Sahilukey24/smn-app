class PenaltyModel {
  const PenaltyModel({
    required this.id,
    required this.orderId,
    required this.penaltyPercent,
    required this.penaltyAmountInr,
    this.daysLate = 0,
    this.graceApplied = false,
    required this.createdAt,
  });

  factory PenaltyModel.fromJson(Map<String, dynamic> json) {
    return PenaltyModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      penaltyPercent: (json['penalty_percent'] as num).toDouble(),
      penaltyAmountInr: (json['penalty_amount_inr'] as num).toDouble(),
      daysLate: (json['days_late'] as num?)?.toInt() ?? 0,
      graceApplied: json['grace_applied'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String orderId;
  final double penaltyPercent;
  final double penaltyAmountInr;
  final int daysLate;
  final bool graceApplied;
  final DateTime createdAt;
}
