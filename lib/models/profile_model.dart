class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.userId,
    required this.role,
    this.displayName,
    this.bio,
    this.analyticsJson,
    this.bankVerified = false,
    this.upiVerified = false,
    this.isLive = false,
    required this.createdAt,
    this.engagementPercent,
    this.avgViews,
    this.basePriceInr,
    this.defaultDeliveryDays,
    this.portfolioLinks,
    this.ratingAvg,
    this.ratingCount = 0,
    this.instagramHandle,
    this.youtubeChannelId,
    this.balanceInr = 0,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final pl = json['portfolio_links'];
    return ProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      analyticsJson: json['analytics_json'],
      bankVerified: json['bank_verified'] as bool? ?? false,
      upiVerified: json['upi_verified'] as bool? ?? false,
      isLive: json['is_live'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      engagementPercent: (json['engagement_percent'] as num?)?.toDouble(),
      avgViews: (json['avg_views'] as num?)?.toDouble(),
      basePriceInr: (json['base_price_inr'] as num?)?.toDouble(),
      defaultDeliveryDays: (json['default_delivery_days'] as num?)?.toInt(),
      portfolioLinks: pl is List ? pl.cast<Map<String, dynamic>>() : null,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      instagramHandle: json['instagram_handle'] as String?,
      youtubeChannelId: json['youtube_channel_id'] as String?,
      balanceInr: (json['balance_inr'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String userId;
  final String role;
  final String? displayName;
  final String? bio;
  final dynamic analyticsJson;
  final bool bankVerified;
  final bool upiVerified;
  final bool isLive;
  final DateTime createdAt;
  final double? engagementPercent;
  final double? avgViews;
  final double? basePriceInr;
  final int? defaultDeliveryDays;
  final List<Map<String, dynamic>>? portfolioLinks;
  final double? ratingAvg;
  final int ratingCount;
  final String? instagramHandle;
  final String? youtubeChannelId;
  final double balanceInr;
}
