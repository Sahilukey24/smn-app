import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/post_service.dart';
import '../../widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId});

  /// If null, show current user's profile (with edit). Else view-only.
  final String? userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final PostService _postService = PostService();

  Profile? _profile;
  List<Post> _posts = [];
  bool _loading = true;
  String? _error;

  bool get _isOwnProfile =>
      widget.userId == null || widget.userId == _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.userId ?? _authService.currentUser?.id;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _profileService.getProfile(uid);
      final posts = await _postService.getPostsByUser(uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _posts = posts;
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

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error ?? 'Profile not found'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _isOwnProfile ? context.pop() : context.go('/home'),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final isOwner = _authService.currentUser?.id == _profile!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile!.username.isNotEmpty ? _profile!.username : 'Profile'),
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: _profile!.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(_profile!.avatarUrl!)
                    : null,
                child: _profile!.avatarUrl == null || _profile!.avatarUrl!.isEmpty
                    ? Text(
                        (_profile!.username.isNotEmpty
                                ? _profile!.username.substring(0, 1)
                                : '?')
                            .toUpperCase(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                _profile!.username.isNotEmpty ? _profile!.username : 'No username',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (_profile!.email.isNotEmpty)
                Text(
                  _profile!.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              Chip(
                label: Text(_profile!.role),
                backgroundColor: theme.colorScheme.secondaryContainer,
              ),
              if (isOwner) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit profile'),
                ),
              ],
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Posts',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No posts yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ..._posts.map(
                  (post) => PostCard(
                    post: post,
                    onLike: () async {
                      await _postService.toggleLike(post.id);
                      _load();
                    },
                    onCommentTap: () => context.push('/post/${post.id}'),
                    canDelete: isOwner,
                    onDelete: isOwner
                        ? () async {
                            await _postService.deletePost(post.id);
                            _load();
                          }
                        : null,
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
