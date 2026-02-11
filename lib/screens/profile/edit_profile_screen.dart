import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final StorageService _storageService = StorageService();

  Profile? _profile;
  File? _imageFile;
  bool _loading = false;
  bool _initialLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await _profileService.getCurrentProfile();
    if (profile != null && mounted) {
      _usernameController.text = profile.username;
      setState(() {
        _profile = profile;
        _initialLoad = false;
      });
    } else {
      setState(() => _initialLoad = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 80);
    if (x != null && mounted) setState(() => _imageFile = File(x.path));
  }

  Future<void> _save() async {
    final uid = _authService.currentUser?.id;
    if (uid == null || _profile == null) return;
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Username is required.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      String? avatarUrl = _profile!.avatarUrl;
      if (_imageFile != null) {
        avatarUrl = await _storageService.uploadAvatar(userId: uid, file: _imageFile!);
      }
      await _profileService.updateProfile(
        userId: uid,
        username: username,
        avatarUrl: avatarUrl,
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
    if (_initialLoad) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!) as ImageProvider
                    : (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(_profile!.avatarUrl!) as ImageProvider
                        : null),
                child: _imageFile == null &&
                        (_profile?.avatarUrl == null || _profile!.avatarUrl!.isEmpty)
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
