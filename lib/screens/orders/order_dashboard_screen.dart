import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../models/order_model.dart';
import '../../services/order_finance_service.dart';
import '../../services/order_hire_service.dart';
import '../../services/order_service.dart' as core_order;

/// Order dashboard: buyer view, provider view, order status timeline.
class OrderDashboardScreen extends StatefulWidget {
  const OrderDashboardScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDashboardScreen> createState() => _OrderDashboardScreenState();
}

class _OrderDashboardScreenState extends State<OrderDashboardScreen> {
  final OrderHireService _hireService = OrderHireService();

  OrderModel? _order;
  List<Map<String, dynamic>> _timeline = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _hireService.getOrderWithTimeline(widget.orderId);
      if (data != null) {
        _order = OrderModel.fromJson(data);
        _timeline = List<Map<String, dynamic>>.from((data['order_timeline'] as List? ?? []));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found')),
      );
    }
    final o = _order!;
    final isBuyer = userId == o.buyerId;
    final isProvider = userId == o.providerId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${o.id.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => context.push('/order/${widget.orderId}'),
            tooltip: 'Full order detail',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Status'),
              trailing: Chip(label: Text(o.status)),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isBuyer ? 'You (buyer)' : 'You (provider)', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text('Total: ₹${o.totalInr.toStringAsFixed(0)}', style: theme.textTheme.titleMedium),
                  if (o.platformChargeInr > 0)
                    Text('Platform fee: ₹${o.platformChargeInr.toStringAsFixed(0)}', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  ...o.items.map((i) => ListTile(
                        dense: true,
                        title: Text(i.serviceName),
                        trailing: Text('₹${i.priceInr.toStringAsFixed(0)}'),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Timeline', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_timeline.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No timeline entries yet.'),
              ),
            )
          else
            ..._timeline.map((e) {
              final at = e['created_at'] != null ? DateTime.tryParse(e['created_at'] as String) : null;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_iconForEvent(e['event_type'] as String?), size: 20),
                  ),
                  title: Text(e['title'] as String? ?? ''),
                  subtitle: Text(
                    [
                      if (e['description'] != null) e['description'] as String,
                      if (at != null) at.toIso8601String().substring(0, 16),
                    ].join(' • '),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          if (isProvider && o.status == AppConstants.orderInProgress)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(
                onPressed: () => context.push('/order/${widget.orderId}/delivery'),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload delivery'),
              ),
            ),
          if (isBuyer && o.status == AppConstants.orderDelivered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(
                onPressed: () async {
                  final done = await OrderFinanceService().approveAndComplete(widget.orderId);
                  if (!done) await core_order.OrderService().markCompleted(widget.orderId);
                  _load();
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Approve & complete'),
              ),
            ),
          OutlinedButton(
            onPressed: () => context.push('/order/${widget.orderId}'),
            child: const Text('View full order detail'),
          ),
        ],
      ),
    );
  }

  IconData _iconForEvent(String? type) {
    switch (type) {
      case 'created':
        return Icons.add_circle_outline;
      case 'payment_received':
        return Icons.payment;
      case 'delivered':
        return Icons.delivery_dining;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.history;
    }
  }
}
