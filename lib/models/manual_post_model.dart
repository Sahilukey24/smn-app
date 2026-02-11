class ManualPostModel {
  const ManualPostModel({
    required this.id,
    required this.profileId,
    this.sourceId,
    this.postUrl,
    this.views,
    this.likes,
    this.comments,
    this.shares,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  factory ManualPostModel.fromJson(Map<String, dynamic> json) {
    return ManualPostModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      sourceId: json['source_id'] as String?,
      postUrl: json['post_url'] as String?,
      views: (json['views'] as num?)?.toInt(),
      likes: (json['likes'] as num?)?.toInt(),
      comments: (json['comments'] as num?)?.toInt(),
      shares: (json['shares'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String profileId;
  final String? sourceId;
  final String? postUrl;
  final int? views;
  final int? likes;
  final int? comments;
  final int? shares;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
}
