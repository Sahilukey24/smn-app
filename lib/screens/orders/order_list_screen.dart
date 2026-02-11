import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/order_model.dart';
import '../../services/marketplace/order_service.dart';

/// My orders list: open workspace or go to payment/approve.
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key, this.statusFilter});

  final String? statusFilter;

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _orderService.getMyOrders(status: widget.statusFilter);
      if (mounted) setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My orders')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.statusFilter != null ? 'Orders (${widget.statusFilter})' : 'My orders'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _orders.isEmpty
            ? const Center(child: Text('No orders yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, i) {
                  final o = _orders[i];
                  return Card(
                    child: ListTile(
                      title: Text('Order #${o.id.substring(0, 8)}'),
                      subtitle: Text('${o.status} • ₹${o.totalInr.toStringAsFixed(0)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/order/${o.id}/workspace'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
