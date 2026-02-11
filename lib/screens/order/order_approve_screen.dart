import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/mvp_order_service.dart';

/// MVP: Buyer approves order → status completed, credit creator balance.
class OrderApproveScreen extends StatefulWidget {
  const OrderApproveScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderApproveScreen> createState() => _OrderApproveScreenState();
}

class _OrderApproveScreenState extends State<OrderApproveScreen> {
  final MvpOrderService _mvpOrder = MvpOrderService();

  bool _approving = false;
  String? _error;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final order = await _mvpOrder.getOrder(widget.orderId);
    if (mounted) setState(() => _order = order);
  }

  Future<void> _approve() async {
    setState(() {
      _approving = true;
      _error = null;
    });
    try {
      final ok = await _mvpOrder.approve(widget.orderId);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order approved. Creator balance credited.')));
        context.go('/order/${widget.orderId}/workspace');
      } else {
        setState(() {
          _error = 'Could not approve (order may not be delivered yet)';
          _approving = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _approving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _order?['status'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Approve order #${widget.orderId.substring(0, 8)}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_order != null) ...[
              Text('Status: $status', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_order!['total_inr'] != null)
                Text('Amount: ₹${(_order!['total_inr'] as num).toStringAsFixed(0)}', style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: 32),
            if (status == 'delivered')
              FilledButton(
                onPressed: _approving ? null : _approve,
                child: _approving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Approve & complete'),
              )
            else
              Text(
                status != 'delivered' ? 'Order must be delivered before you can approve.' : '',
                style: theme.textTheme.bodyMedium,
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
