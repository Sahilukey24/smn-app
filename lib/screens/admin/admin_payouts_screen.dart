import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_dispute_service.dart';

class AdminPayoutsScreen extends StatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  State<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends State<AdminPayoutsScreen> {
  final AdminDisputeService _admin = AdminDisputeService();

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('orders')
          .select('id, buyer_id, provider_id, total_inr, payout_frozen, status')
          .eq('payout_frozen', true)
          .order('created_at', ascending: false);
      if (mounted) setState(() {
        _orders = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frozen payouts'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _orders.isEmpty
          ? const Center(child: Text('No frozen payouts'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, i) {
                final o = _orders[i];
                return Card(
                  child: ListTile(
                    title: Text('Order ${(o['id'] as String).substring(0, 8)}'),
                    subtitle: Text('₹${(o['total_inr'] as num).toStringAsFixed(0)} • ${o['status']}'),
                    trailing: FilledButton(
                      onPressed: () async {
                        await _admin.releasePayout(o['id'] as String);
                        _load();
                      },
                      child: const Text('Release'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
