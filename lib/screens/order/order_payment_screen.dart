import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/mvp_order_service.dart';

/// MVP: Simulate payment success → order status in_progress → navigate to workspace.
class OrderPaymentScreen extends StatefulWidget {
  const OrderPaymentScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderPaymentScreen> createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  final MvpOrderService _mvpOrder = MvpOrderService();

  bool _processing = false;
  String? _error;

  Future<void> _simulatePaymentSuccess() async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final ok = await _mvpOrder.markPaymentSuccess(widget.orderId);
      if (!mounted) return;
      if (ok) {
        context.go('/order/${widget.orderId}/workspace');
      } else {
        setState(() {
          _error = 'Payment failed or order already paid';
          _processing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.payment, size: 64),
            const SizedBox(height: 24),
            Text(
              'Simulate payment success',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Order #${widget.orderId.substring(0, 8)}',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _processing ? null : _simulatePaymentSuccess,
              child: _processing
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Complete payment'),
            ),
          ],
        ),
      ),
    );
  }
}
