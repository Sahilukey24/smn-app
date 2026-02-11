import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/marketplace/auth_service.dart';
import '../../services/marketplace/order_service.dart';

class DashboardBusinessScreen extends StatefulWidget {
  const DashboardBusinessScreen({super.key});

  @override
  State<DashboardBusinessScreen> createState() => _DashboardBusinessScreenState();
}

class _DashboardBusinessScreenState extends State<DashboardBusinessScreen> {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();

  int _orderCount = 0;
  int _pendingApprovalCount = 0;
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
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final pendingApproval = orders.where((o) => o.buyerId == userId && o.status == 'delivered').length;
      if (mounted) {
        setState(() {
          _orderCount = orders.length;
          _pendingApprovalCount = pendingApproval;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business dashboard'),
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
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: const Text('My orders'),
                      subtitle: Text('$_orderCount orders'),
                      onTap: () => context.push('/orders'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.pending_actions),
                      title: const Text('Pending approval'),
                      subtitle: Text('$_pendingApprovalCount awaiting your approval'),
                      onTap: () => context.push('/orders?status=delivered'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.chat),
                      title: const Text('Open workspace'),
                      subtitle: const Text('Chat, delivery, timeline'),
                      onTap: () => context.push('/orders'),
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.payment),
                      title: Text('Payments'),
                      subtitle: Text('History'),
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.rate_review_outlined),
                      title: Text('Reviews'),
                      subtitle: Text('Track feedback'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
