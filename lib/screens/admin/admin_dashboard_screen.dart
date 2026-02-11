import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_dispute_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDisputeService _adminService = AdminDisputeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/marketplace'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Manual analytics'),
              subtitle: const Text('Approve / reject manual posts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/manual-posts'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gavel),
              title: const Text('Disputes'),
              subtitle: const Text('Resolve and close disputes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/disputes'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payouts'),
              subtitle: const Text('Release frozen payouts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/payouts'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Ban users'),
              subtitle: const Text('Ban / unban users'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/ban-users'),
            ),
          ),
        ],
      ),
    );
  }
}
