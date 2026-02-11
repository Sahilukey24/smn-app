class OrderDeliveryModel {
  const OrderDeliveryModel({
    required this.id,
    required this.orderId,
    required this.uploadedBy,
    required this.filePath,
    this.fileSizeBytes,
    this.fileType,
    required this.createdAt,
  });

  factory OrderDeliveryModel.fromJson(Map<String, dynamic> json) {
    return OrderDeliveryModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      filePath: json['file_path'] as String,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      fileType: json['file_type'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String orderId;
  final String uploadedBy;
  final String filePath;
  final int? fileSizeBytes;
  final String? fileType;
  final DateTime createdAt;
}
