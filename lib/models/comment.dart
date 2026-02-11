/// Comment matching Supabase `comments` table.
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatarUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      authorUsername: json['author_username'] as String?,
      authorAvatarUrl: json['author_avatar_url'] as String?,
    );
  }

  final String id;
  final String postId;
  final String userId;
  final String comment;
  final DateTime createdAt;
  final String? authorUsername;
  final String? authorAvatarUrl;
}
