import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_repository.dart';

/// Product-first marketplace: all services from mock repo. Tap → service detail.
class MvpMarketplaceScreen extends StatefulWidget {
  const MvpMarketplaceScreen({super.key});

  @override
  State<MvpMarketplaceScreen> createState() => _MvpMarketplaceScreenState();
}

class _MvpMarketplaceScreenState extends State<MvpMarketplaceScreen> {
  final _repo = MockRepository.instance;
  List<MockServiceModel> _services = [];

  @override
  void initState() {
    super.initState();
    _services = _repo.getServices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        itemBuilder: (context, i) {
          final s = _services[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(s.title, style: theme.textTheme.titleMedium),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  Text('₹${s.price.toStringAsFixed(0)} • ${s.creatorName}'),
                  Text('⭐ ${s.rating} • ${s.deliveryDays} days delivery'),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/mvp/service/${s.id}'),
            ),
          );
        },
      ),
    );
  }
}
