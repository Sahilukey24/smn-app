import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_repository.dart';

/// Product-first service detail: description, price, delivery, creator. Button → HIRE NOW.
class MvpServiceDetailScreen extends StatefulWidget {
  const MvpServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  State<MvpServiceDetailScreen> createState() => _MvpServiceDetailScreenState();
}

class _MvpServiceDetailScreenState extends State<MvpServiceDetailScreen> {
  final _repo = MockRepository.instance;
  MockServiceModel? _service;

  @override
  void initState() {
    super.initState();
    _service = _repo.getServiceById(widget.serviceId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: const Center(child: Text('Service not found')),
      );
    }
    final s = _service!;
    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹${s.price.toStringAsFixed(0)}', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Delivery: ${s.deliveryDays} days', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text('Creator: ${s.creatorName} • ⭐ ${s.rating}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push('/hire', extra: s),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('HIRE NOW'),
          ),
        ],
      ),
    );
  }
}
