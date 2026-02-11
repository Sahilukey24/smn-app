import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category_model.dart';
import '../../models/service_model.dart';

/// Marketplace listing: all services, filter by category, sort by price, open service detail.
class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  List<ServiceModel> _services = [];
  List<CategoryModel> _categories = [];
  String? _filterCategoryId;
  bool _sortPriceAsc = true;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadServices();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await Supabase.instance.client.from('categories').select().order('sort_order');
      setState(() => _categories = (res as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList());
    } catch (_) {}
  }

  bool _sortByRating = false;

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final liveProfiles = await client.from('profiles').select('id').eq('is_live', true);
      final liveIds = (liveProfiles as List).map((e) => e['id'] as String).toList();
      if (liveIds.isEmpty) {
        setState(() => _services = [], _loading = false);
        return;
      }
      var q = client.from('services').select('*, categories(name)').eq('is_active', true).inFilter('profile_id', liveIds);
      if (_filterCategoryId != null) {
        q = q.eq('category_id', _filterCategoryId!);
      }
      q = q.order('price_inr', ascending: _sortPriceAsc);
      final res = await q;
      List<ServiceModel> list = (res as List).map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
      if (_sortByRating) {
        final withRating = await client.from('profiles').select('id, rating_avg').inFilter('id', list.map((s) => s.profileId).toSet().toList());
        final ratingMap = {for (var r in withRating as List) r['id'] as String: (r['rating_avg'] as num?)?.toDouble()};
        list.sort((a, b) => (ratingMap[b.profileId] ?? 0).compareTo(ratingMap[a.profileId] ?? 0));
      }
      setState(() {
        _services = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: Icon(_sortByRating ? Icons.star : (_sortPriceAsc ? Icons.arrow_upward : Icons.arrow_downward)),
            onPressed: () {
              setState(() {
                _sortByRating = !_sortByRating;
                _loadServices();
              });
            },
            tooltip: _sortByRating ? 'Sort by rating' : (_sortPriceAsc ? 'Price low to high' : 'Price high to low'),
          ),
          if (!_sortByRating)
            IconButton(
              icon: Icon(_sortPriceAsc ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () {
                setState(() {
                  _sortPriceAsc = !_sortPriceAsc;
                  _loadServices();
                });
              },
              tooltip: _sortPriceAsc ? 'Price low to high' : 'Price high to low',
            ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterCategoryId == null,
                  onSelected: (_) {
                    setState(() {
                      _filterCategoryId = null;
                      _loadServices();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ..._categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: _filterCategoryId == c.id,
                        onSelected: (_) {
                          setState(() {
                            _filterCategoryId = c.id;
                            _loadServices();
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? const Center(child: Text('No services found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _services.length,
                        itemBuilder: (context, i) {
                          final s = _services[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(s.name),
                              subtitle: Text(
                                '₹${s.priceInr.toStringAsFixed(0)}${s.deliveryDays != null ? " • ${s.deliveryDays} days" : ""}${s.categoryName != null ? " • ${s.categoryName}" : ""}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/service/${s.id}'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
