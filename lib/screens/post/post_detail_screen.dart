import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/comment_widget.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final _commentController = TextEditingController();

  Post? _post;
  List<Comment> _comments = [];
  bool _loading = true;
  String? _error;
  bool _sendingComment = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final isAdmin = await _profileService.isAdmin();
      final post = await _postService.getPost(widget.postId);
      final comments = post != null ? await _postService.getComments(widget.postId) : <Comment>[];
      if (mounted) {
        setState(() {
          _post = post;
          _comments = comments;
          _isAdmin = isAdmin;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    try {
      await _postService.toggleLike(_post!.id);
      setState(() {
        _post = _post!.copyWith(
          isLiked: !_post!.isLiked,
          likesCount: _post!.likesCount + (_post!.isLiked ? -1 : 1),
        );
      });
    } catch (_) {}
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _post == null) return;
    final uid = _authService.currentUser?.id;
    if (uid == null) return;
    setState(() => _sendingComment = true);
    try {
      final comment = await _postService.addComment(
        postId: _post!.id,
        userId: uid,
        comment: text,
      );
      _commentController.clear();
      setState(() {
        _comments = [..._comments, comment];
        _sendingComment = false;
      });
    } catch (_) {
      setState(() => _sendingComment = false);
    }
  }

  Future<void> _deletePost() async {
    if (_post == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _postService.deletePost(_post!.id);
      if (mounted) context.pop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error ?? 'Post not found'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isOwner = _authService.currentUser?.id == _post!.userId;
    final canDelete = isOwner || _isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deletePost,
              color: theme.colorScheme.error,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(theme),
                  if (_post!.content.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_post!.content, style: theme.textTheme.bodyLarge),
                  ],
                  if (_post!.imageUrl != null && _post!.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _post!.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _post!.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _post!.isLiked ? theme.colorScheme.error : null,
                        ),
                        onPressed: _toggleLike,
                      ),
                      Text('${_post!.likesCount}'),
                      const SizedBox(width: 16),
                      Text('${_comments.length} comments', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const Divider(height: 24),
                  Text('Comments', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._comments.map((c) => CommentWidget(comment: c)),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendingComment ? null : _sendComment,
                    icon: _sendingComment
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: _post!.authorAvatarUrl != null && _post!.authorAvatarUrl!.isNotEmpty
              ? CachedNetworkImageProvider(_post!.authorAvatarUrl!)
              : null,
          child: _post!.authorAvatarUrl == null || _post!.authorAvatarUrl!.isEmpty
              ? Text(
                  (_post!.authorUsername ?? 'U').toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _post!.authorUsername ?? 'User',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                _formatDate(_post!.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}
