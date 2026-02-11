import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_order_store.dart';
import '../../data/mock/mock_repository.dart';

/// Business home: search, categories, featured creators, recently hired, hire history. "Hire a Creator".
class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  final _repo = MockRepository.instance;
  final _store = MockOrderStore.instance;
  final _searchController = TextEditingController();

  static const _categories = ['Video', 'Design', 'Social', 'Ads'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MockServiceModel> get _services => _repo.getServices();
  List<MockOrder> get _myOrders => _store.getOrdersForBuyer('business-1');
  List<MockOrder> get _recentOrders => _myOrders.take(5).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search services or creators',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            Text('Categories', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2,
              children: _categories.map((c) => Card(
                child: InkWell(
                  onTap: () => context.push('/mvp'),
                  child: Center(child: Text(c)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Featured creators', style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/mvp'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _services.length,
                itemBuilder: (context, i) {
                  final s = _services[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Card(
                      child: InkWell(
                        onTap: () => context.push('/business/service/${s.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.creatorName, style: theme.textTheme.titleSmall),
                              Text(s.title, style: theme.textTheme.bodySmall),
                              Text('₹${s.price.toStringAsFixed(0)}', style: theme.textTheme.labelMedium),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Recently hired', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_recentOrders.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No orders yet.')))
            else
              ..._recentOrders.map((o) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(o.serviceName),
                  subtitle: Text('${o.creatorName} • ${o.status}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/workspace/${o.id}'),
                ),
              )),
            const SizedBox(height: 24),
            Text('Hire history', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_myOrders.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No hire history yet.')))
            else
              ..._myOrders.take(3).map((o) => ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(o.serviceName),
                subtitle: Text('₹${o.price.toStringAsFixed(0)} • ${o.status}'),
                onTap: () => context.push('/workspace/${o.id}'),
              )),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/mvp'),
              icon: const Icon(Icons.add),
              label: const Text('Hire a Creator'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
