import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';
import '../models/post.dart';

/// Posts, comments, and likes via Supabase.
class PostService {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  /// Feed: posts with author and like count. Optional filter by current user like.
  Future<List<Post>> getFeed({int limit = 50}) async {
    try {
      final res = await _client
          .from('posts')
          .select('id, user_id, content, image_url, created_at, likes_count, profiles(username, avatar_url)')
          .order('created_at', ascending: false)
          .limit(limit);

      final list = res as List;
      final posts = <Post>[];
      for (final row in list) {
        final map = row as Map<String, dynamic>;
        final profiles = map['profiles'];
        Map<String, dynamic>? author;
        if (profiles is Map) {
          author = profiles as Map<String, dynamic>;
        }
        final post = Post(
          id: map['id'] as String,
          userId: map['user_id'] as String,
          content: map['content'] as String? ?? '',
          imageUrl: map['image_url'] as String?,
          createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
          likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
          authorUsername: author?['username'] as String?,
          authorAvatarUrl: author?['avatar_url'] as String?,
        );
        posts.add(post);
      }

      if (_userId != null && posts.isNotEmpty) {
        final postIds = posts.map((p) => p.id).toList();
        final likesRes = await _client
            .from('likes')
            .select('post_id')
            .eq('user_id', _userId!)
            .inFilter('post_id', postIds);
        final likedIds = (likesRes as List)
            .map((e) => (e as Map<String, dynamic>)['post_id'] as String)
            .toSet();
        return posts
            .map((p) => p.copyWith(isLiked: likedIds.contains(p.id)))
            .toList();
      }
      return posts;
    } catch (e) {
      rethrow;
    }
  }

  /// Posts by user (for profile).
  Future<List<Post>> getPostsByUser(String userId, {int limit = 50}) async {
    try {
      final res = await _client
          .from('posts')
          .select('id, user_id, content, image_url, created_at, likes_count, profiles(username, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final list = res as List;
      final posts = <Post>[];
      for (final row in list) {
        final map = row as Map<String, dynamic>;
        final profiles = map['profiles'];
        Map<String, dynamic>? author;
        if (profiles is Map) author = profiles as Map<String, dynamic>;
        posts.add(Post(
          id: map['id'] as String,
          userId: map['user_id'] as String,
          content: map['content'] as String? ?? '',
          imageUrl: map['image_url'] as String?,
          createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
          likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
          authorUsername: author?['username'] as String?,
          authorAvatarUrl: author?['avatar_url'] as String?,
        ));
      }

      if (_userId != null && posts.isNotEmpty) {
        final likedRes = await _client
            .from('likes')
            .select('post_id')
            .eq('user_id', _userId!)
            .inFilter('post_id', posts.map((p) => p.id).toList());
        final likedIds = (likedRes as List)
            .map((e) => (e as Map<String, dynamic>)['post_id'] as String)
            .toSet();
        return posts
            .map((p) => p.copyWith(isLiked: likedIds.contains(p.id)))
            .toList();
      }
      return posts;
    } catch (e) {
      rethrow;
    }
  }

  Future<Post?> getPost(String postId) async {
    try {
      final res = await _client
          .from('posts')
          .select('id, user_id, content, image_url, created_at, likes_count, profiles(username, avatar_url)')
          .eq('id', postId)
          .maybeSingle();
      if (res == null) return null;
      final map = res as Map<String, dynamic>;
      final profiles = map['profiles'];
      Map<String, dynamic>? author;
      if (profiles is Map) author = profiles as Map<String, dynamic>;
      final post = Post(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        content: map['content'] as String? ?? '',
        imageUrl: map['image_url'] as String?,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
        likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
        authorUsername: author?['username'] as String?,
        authorAvatarUrl: author?['avatar_url'] as String?,
      );
      if (_userId != null) {
        final likeRes = await _client
            .from('likes')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', _userId!)
            .maybeSingle();
        return post.copyWith(isLiked: likeRes != null);
      }
      return post;
    } catch (e) {
      rethrow;
    }
  }

  Future<Post> createPost({
    required String userId,
    required String content,
    String? imageUrl,
  }) async {
    final res = await _client.from('posts').insert({
      'user_id': userId,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
    }).select('''
      id,
      user_id,
      content,
      image_url,
      created_at,
      likes_count
    ''').single();
    final map = res as Map<String, dynamic>;
    return Post(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      likesCount: 0,
    );
  }

  Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  Future<void> toggleLike(String postId) async {
    final uid = _userId;
    if (uid == null) return;
    final existing = await _client
        .from('likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();
    if (existing != null) {
      await _client.from('likes').delete().eq('post_id', postId).eq('user_id', uid);
    } else {
      await _client.from('likes').insert({'post_id': postId, 'user_id': uid});
    }
    // likes_count is updated by DB trigger
  }

  Future<List<Comment>> getComments(String postId, {int limit = 100}) async {
      final res = await _client
        .from('comments')
        .select('id, post_id, user_id, comment, created_at, profiles(username, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .limit(limit);
    return (res as List)
        .map((e) {
          final map = e as Map<String, dynamic>;
          final profiles = map['profiles'];
          Map<String, dynamic>? author;
          if (profiles is Map) author = profiles as Map<String, dynamic>;
          return Comment(
            id: map['id'] as String,
            postId: map['post_id'] as String,
            userId: map['user_id'] as String,
            comment: map['comment'] as String? ?? '',
            createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
            authorUsername: author?['username'] as String?,
            authorAvatarUrl: author?['avatar_url'] as String?,
          );
        })
        .toList();
  }

  Future<Comment> addComment({
    required String postId,
    required String userId,
    required String comment,
  }) async {
    final res = await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'comment': comment,
    }).select().single();
    final map = res as Map<String, dynamic>;
    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      comment: map['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
