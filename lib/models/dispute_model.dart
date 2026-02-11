import '../core/constants.dart';

class DisputeModel {
  const DisputeModel({
    required this.id,
    required this.orderId,
    required this.raisedBy,
    required this.reason,
    required this.status,
    this.adminNotes,
    this.resolvedAt,
    required this.createdAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      raisedBy: json['raised_by'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String? ?? AppConstants.disputeOpen,
      adminNotes: json['admin_notes'] as String?,
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'] as String) : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String orderId;
  final String raisedBy;
  final String reason;
  final String status;
  final String? adminNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;
}
