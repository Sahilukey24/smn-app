import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/marketplace/auth_service.dart';
import '../../services/marketplace/order_service.dart';
import '../../services/marketplace/profile_service.dart' show MarketplaceProfileService;

class DashboardProviderScreen extends StatefulWidget {
  const DashboardProviderScreen({super.key});

  @override
  State<DashboardProviderScreen> createState() => _DashboardProviderScreenState();
}

class _DashboardProviderScreenState extends State<DashboardProviderScreen> {
  final AuthService _authService = AuthService();
  final MarketplaceProfileService _profileService = MarketplaceProfileService();
  final OrderService _orderService = OrderService();

  int _pendingCount = 0;
  int _inProgressCount = 0;
  double _balanceInr = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _orderService.getMyOrders();
      final profiles = await _profileService.getMyProfiles();
      final pending = orders.where((o) => o.status == 'pending').length;
      final inProgress = orders.where((o) => o.status == 'in_progress' || o.status == 'delivered' || o.status == 'revision').length;
      final balance = profiles.fold<double>(0, (s, p) => s + (p.balanceInr));
      if (mounted) {
        setState(() {
          _pendingCount = pending;
          _inProgressCount = inProgress;
          _balanceInr = balance;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            onPressed: () => context.go('/marketplace'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions),
                      title: const Text('Pending (deadline)'),
                      subtitle: Text('$_pendingCount orders'),
                      onTap: () => context.push('/orders?status=pending'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.work_outline),
                      title: const Text('Orders in progress'),
                      subtitle: Text('$_inProgressCount orders'),
                      onTap: () => context.push('/orders?status=in_progress'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: const Text('Upload delivery'),
                      subtitle: const Text('Deliver for in-progress orders'),
                      onTap: () => context.push('/orders?status=in_progress'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet),
                      title: const Text('Earnings preview'),
                      subtitle: Text('₹${_balanceInr.toStringAsFixed(0)} balance'),
                      onTap: () {},
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.analytics_outlined),
                      title: const Text('Earnings & reports'),
                      subtitle: const Text('PDF / Excel'),
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
