import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/dispute_model.dart';
import '../../repositories/dispute_repository.dart';

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final DisputeRepository _repo = DisputeRepository(Supabase.instance.client);

  DisputeModel? _dispute;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _repo.getByOrderId(widget.orderId);
      if (mounted) setState(() {
        _dispute = d;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.length < 20) {
      setState(() => _error = 'Please provide at least 20 characters.');
      return;
    }
    setState(() => _submitting = true);
    _error = null;
    try {
      final d = await _repo.create(orderId: widget.orderId, reason: reason);
      if (d != null && mounted) {
        setState(() => _dispute = d);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute raised. Payout is frozen until resolved.')));
      } else {
        setState(() => _error = 'Failed to create dispute');
      }
    } catch (_) {
      setState(() => _error = 'Failed');
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_dispute != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: const Text('Status'),
                trailing: Chip(label: Text(_dispute!.status)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Raised: ${_dispute!.createdAt.toIso8601String()}'),
            const SizedBox(height: 8),
            Text('Reason:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(_dispute!.reason),
            if (_dispute!.adminNotes != null) ...[
              const SizedBox(height: 16),
              Text('Admin notes:', style: theme.textTheme.titleSmall),
              Text(_dispute!.adminNotes!),
            ],
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Raise dispute')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Raising a dispute will freeze the order payout until an admin reviews. Use for policy violations or delivery issues.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason (min 20 characters)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit dispute'),
            ),
          ],
        ),
      ),
    );
  }
}
