import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/marketplace/auth_service.dart';
import '../../services/marketplace/profile_service.dart';

class ProfileCreateScreen extends StatefulWidget {
  const ProfileCreateScreen({super.key, this.role});

  final String? role;

  @override
  State<ProfileCreateScreen> createState() => _ProfileCreateScreenState();
}

class _ProfileCreateScreenState extends State<ProfileCreateScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final role = widget.role ?? _selectedRole;
    if (role == null || role == AppConstants.roleBusinessOwner) {
      context.go('/marketplace');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _profileService.upsertProfile(
        role: role,
        displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      );
      if (profile != null && mounted) {
        if (role == AppConstants.roleCreator) {
          context.go('/creator/setup/${profile.id}');
        } else if (role == AppConstants.roleVideographer) {
          context.go('/videographer/setup/${profile.id}');
        } else {
          context.go('/freelancer/setup/${profile.id}');
        }
      }
    } catch (_) {
      setState(() => _error = 'Failed to create profile');
    }
    setState(() => _loading = false);
  }

  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = widget.role ?? _selectedRole;
    final isProvider = role != null && role != AppConstants.roleBusinessOwner;

    return Scaffold(
      appBar: AppBar(title: const Text('Create profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.role == null) ...[
              Text('Select role', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...AppConstants.providerRoles.map((r) {
                final label = r == AppConstants.roleCreator
                    ? 'Creator'
                    : r == AppConstants.roleVideographer
                        ? 'Videographer'
                        : 'Freelancer';
                return RadioListTile<String>(
                  title: Text(label),
                  value: r,
                  groupValue: _selectedRole,
                  onChanged: (v) => setState(() => _selectedRole = v),
                );
              }),
              const SizedBox(height: 24),
            ],
            if (isProvider) ...[
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
