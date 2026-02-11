import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_repository.dart';
import '../../services/payment/mock_payment_service.dart';

/// Order summary, platform fee ₹15, "Continue to Pay" → mock payment → workspace.
class HireScreen extends StatefulWidget {
  const HireScreen({super.key, this.service});

  final MockServiceModel? service;

  @override
  State<HireScreen> createState() => _HireScreenState();
}

class _HireScreenState extends State<HireScreen> {
  static const double platformFee = 15;

  final _repo = MockRepository.instance;
  final _payment = MockPaymentService.instance;

  bool _paying = false;
  String? _error;

  String get _buyerId => 'buyer-1';
  double get _price => widget.service?.price ?? 0;
  double get _total => _price + platformFee;

  Future<void> _continueToPay() async {
    final service = widget.service;
    if (service == null) return;
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final order = _repo.createOrder(
        serviceId: service.id,
        buyerId: _buyerId,
        creatorId: service.creatorId,
        price: service.price,
      );
      if (order == null) {
        setState(() => _error = 'Could not create order');
        setState(() => _paying = false);
        return;
      }
      final success = await _payment.simulatePayment();
      if (!mounted) return;
      if (success) {
        _repo.updateOrderStatus(order.id, 'in_progress');
        _repo.addTimelineEvent(order.id, 'payment_received', 'Payment successful. Chat unlocked.');
        context.go('/mvp/workspace/${order.id}');
      } else {
        setState(() => _error = 'Payment failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = widget.service;
    if (service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hire')),
        body: const Center(child: Text('Select a service first')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Order summary')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(service.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Service', '₹${service.price.toStringAsFixed(0)}'),
                    _row('Platform fee', '₹${platformFee.toStringAsFixed(0)}'),
                    const Divider(),
                    _row('Total', '₹${_total.toStringAsFixed(0)}', isBold: true),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _paying ? null : _continueToPay,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _paying
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue to Pay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(value, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }
}
