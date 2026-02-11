import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();

  List<Post> _posts = [];
  bool _loading = true;
  String? _error;
  bool _canPost = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final canPost = await _profileService.canPost();
      final isAdmin = await _profileService.isAdmin();
      final posts = await _postService.getFeed();
      if (mounted) {
        setState(() {
          _posts = posts;
          _canPost = canPost;
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

  Future<void> _toggleLike(Post post) async {
    try {
      await _postService.toggleLike(post.id);
      setState(() {
        final i = _posts.indexWhere((p) => p.id == post.id);
        if (i >= 0) {
          _posts[i] = post.copyWith(
            isLiked: !post.isLiked,
            likesCount: post.likesCount + (post.isLiked ? -1 : 1),
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _deletePost(Post post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _postService.deletePost(post.id);
      if (mounted) {
        setState(() => _posts.removeWhere((p) => p.id == post.id));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.feed_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No posts yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_canPost)
                              TextButton(
                                onPressed: () => context.push('/post/create'),
                                child: const Text('Create the first post'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _posts.length,
                        itemBuilder: (context, i) {
                          final post = _posts[i];
                          final isOwner = _authService.currentUser?.id == post.userId;
                          return PostCard(
                            post: post,
                            onLike: () => _toggleLike(post),
                            onCommentTap: () => context.push('/post/${post.id}'),
                            onDelete: () => _deletePost(post),
                            canDelete: isOwner || _isAdmin,
                          );
                        },
                      ),
      ),
      floatingActionButton: _canPost
          ? FloatingActionButton(
              onPressed: () => context.push('/post/create'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
