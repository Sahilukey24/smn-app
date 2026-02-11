import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();

  File? _imageFile;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkCanPost();
  }

  Future<void> _checkCanPost() async {
    final canPost = await ProfileService().canPost();
    if (!canPost && mounted) context.pop();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (x != null && mounted) setState(() => _imageFile = File(x.path));
  }

  Future<void> _submit() async {
    final uid = _authService.currentUser?.id;
    if (uid == null) return;
    final content = _contentController.text.trim();
    if (content.isEmpty && _imageFile == null) {
      setState(() => _error = 'Add some text or an image.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _storageService.uploadPostImage(userId: uid, file: _imageFile!);
      }
      await _postService.createPost(
        userId: uid,
        content: content.isEmpty ? '' : content,
        imageUrl: imageUrl,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            if (_imageFile != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _imageFile = null),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Add image'),
            ),
          ],
        ),
      ),
    );
  }
}
