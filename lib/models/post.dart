/// Post matching Supabase `posts` table. Author info may be joined from profiles.
class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likesCount = 0,
    this.authorUsername,
    this.authorAvatarUrl,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      authorUsername: json['author_username'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likesCount;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final bool isLiked;

  Post copyWith({
    int? likesCount,
    bool? isLiked,
  }) {
    return Post(
      id: id,
      userId: userId,
      content: content,
      imageUrl: imageUrl,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
