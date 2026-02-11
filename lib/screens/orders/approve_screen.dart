import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_order_store.dart';
import '../../services/earnings/mock_earnings_service.dart';

/// Approve → order completed, creator_balance += price, platform_balance += 15.
class ApproveScreen extends StatefulWidget {
  const ApproveScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<ApproveScreen> createState() => _ApproveScreenState();
}

class _ApproveScreenState extends State<ApproveScreen> {
  final _store = MockOrderStore.instance;
  final _earnings = MockEarningsService.instance;

  bool _approving = false;

  Future<void> _approve() async {
    final order = _store.getOrderById(widget.orderId);
    if (order == null || order.status != 'delivered') return;
    setState(() => _approving = true);
    _earnings.onApprove(widget.orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order approved. Creator earnings updated.')),
      );
      context.go('/workspace/${widget.orderId}');
    }
    setState(() => _approving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = _store.getOrderById(widget.orderId);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approve')),
        body: const Center(child: Text('Order not found')),
      );
    }
    final canApprove = order.status == 'delivered';

    return Scaffold(
      appBar: AppBar(title: Text('Approve • ${order.serviceName}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: ${order.status}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Amount: ₹${order.price.toStringAsFixed(0)}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Creator: ${order.creatorName}', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 32),
            if (canApprove)
              FilledButton(
                onPressed: _approving ? null : _approve,
                child: _approving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Approve & Complete'),
              )
            else
              Text('Order must be delivered before you can approve.', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
