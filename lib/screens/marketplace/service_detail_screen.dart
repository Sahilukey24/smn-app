import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/service_model.dart';

/// Service detail: show service, Hire button → hire confirm (price breakdown, pay) → order dashboard.
class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceModel? _service;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Supabase.instance.client
          .from('services')
          .select('*, categories(name)')
          .eq('id', widget.serviceId)
          .eq('is_active', true)
          .maybeSingle();
      setState(() {
        _service = res != null ? ServiceModel.fromJson(res as Map<String, dynamic>) : null;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _hire() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _service == null) {
      setState(() => _error = 'Please log in to hire');
      return;
    }
    context.push('/hire/confirm/${widget.serviceId}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: const Center(child: Text('Service not found')),
      );
    }
    final s = _service!;
    return Scaffold(
      appBar: AppBar(title: Text(s.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (s.demoImageUrl != null || s.demoVideoUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('Sample', style: theme.textTheme.titleSmall),
              ),
            Text(s.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('₹${s.priceInr.toStringAsFixed(0)}${s.deliveryDays != null ? " • ${s.deliveryDays} days delivery" : ""}',
                style: theme.textTheme.bodyLarge),
            if (s.categoryName != null) Text(s.categoryName!, style: theme.textTheme.bodySmall),
            if (s.description != null && s.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(s.description!),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _hire,
              child: const Text('Hire – continue to pay'),
            ),
          ],
        ),
      ),
    );
  }
}
