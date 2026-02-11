import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_repository.dart';

/// Service detail for business flow: price card, platform fee ₹15, delivery days, Hire Now → hire_confirm.
class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _repo = MockRepository.instance;
  MockServiceModel? _service;

  static const double platformFee = 15;

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
    final total = s.price + platformFee;

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
                  Text('Price', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Base price'),
                      Text('₹${s.price.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform fee'),
                      Text('₹${platformFee.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery'),
                      Text('${s.deliveryDays} days'),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleMedium),
                      Text('₹${total.toStringAsFixed(0)}', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(s.creatorName),
              subtitle: Text('⭐ ${s.rating}'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push('/hire', extra: s),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Hire Now'),
          ),
        ],
      ),
    );
  }
}
