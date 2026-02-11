import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_dispute_service.dart';

class AdminBanScreen extends StatefulWidget {
  const AdminBanScreen({super.key});

  @override
  State<AdminBanScreen> createState() => _AdminBanScreenState();
}

class _AdminBanScreenState extends State<AdminBanScreen> {
  final AdminDisputeService _admin = AdminDisputeService();
  final _userIdController = TextEditingController();
  bool _ban = true;
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    final ok = await _admin.setUserBanned(userId, _ban);
    if (mounted) setState(() {
      _loading = false;
      _message = ok ? 'Done' : 'Failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ban / Unban user')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID (UUID)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Ban'), icon: Icon(Icons.block)),
                ButtonSegment(value: false, label: Text('Unban'), icon: Icon(Icons.check_circle)),
              ],
              selected: {_ban},
              onSelectionChanged: (s) => setState(() => _ban = s.first),
            ),
            const SizedBox(height: 24),
            if (_message != null) Text(_message!),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
