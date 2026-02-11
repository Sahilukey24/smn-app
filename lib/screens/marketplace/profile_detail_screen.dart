import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors.dart';
import '../../models/profile_model.dart';
import '../../models/service_model.dart';
import '../../services/marketplace/cart_service.dart';
import '../../services/marketplace/profile_service.dart';
import '../../widgets/analytics_chart.dart';
import '../../widgets/earnings_calculator.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final ProfileService _profileService = ProfileService();
  final CartService _cartService = CartService();

  ProfileModel? _profile;
  List<ServiceModel> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await _profileService.getProfile(widget.profileId);
      final services = await _profileService.getServicesForProfile(widget.profileId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _services = services;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading || _profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Provider')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile!.displayName ?? 'Provider'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_profile!.bio ?? 'No bio', style: theme.textTheme.bodyMedium),
                    if (_profile!.engagementPercent != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Engagement: ${_profile!.engagementPercent!.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (_profile!.avgViews != null)
                      Text(
                        'Avg views: ${_profile!.avgViews!.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
            if (_profile!.analyticsJson is List && (_profile!.analyticsJson as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              AnalyticsChart(
                values: (_profile!.analyticsJson as List).map((e) => (e is num ? e : 0.0).toDouble()).toList(),
                label: 'Last ${(_profile!.analyticsJson as List).length} posts (views)',
              ),
            ],
            const SizedBox(height: 16),
            Text('Services', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._services.map((s) {
              return Card(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text('₹${s.priceInr.toStringAsFixed(0)}${s.deliveryDays != null ? ' • ${s.deliveryDays} days' : ''}'),
                  trailing: FilledButton(
                    onPressed: () async {
                      try {
                        await _cartService.addToCart(s.id, widget.profileId);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                      } on CartCreatorMismatchException {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart can only have one creator. Clear cart or add from this creator only.')),
                          );
                        }
                      }
                    },
                    child: const Text('Add to cart'),
                  ),
                ),
              );
            }),
            if (_services.isNotEmpty)
              EarningsCalculator(
                priceInr: _services.first.priceInr,
                label: 'They receive (per ₹${_services.first.priceInr.toStringAsFixed(0)} order)',
              ),
          ],
        ),
      ),
    );
  }
}
