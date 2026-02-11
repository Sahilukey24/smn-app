import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_order_store.dart';
import '../../services/payment/mock_payment_service.dart';

/// Hire confirm (business flow): service name, creator name, base price, platform fee ₹15, total. Continue to Pay → mock pay → workspace.
class BusinessHireConfirmScreen extends StatefulWidget {
  const BusinessHireConfirmScreen({super.key, this.service});

  final MockServiceModel? service;

  @override
  State<BusinessHireConfirmScreen> createState() => _BusinessHireConfirmScreenState();
}

class _BusinessHireConfirmScreenState extends State<BusinessHireConfirmScreen> {
  static const double platformFee = 15;

  final _store = MockOrderStore.instance;
  final _payment = MockPaymentService.instance;

  bool _paying = false;
  String? _error;

  double get _basePrice => widget.service?.price ?? 0;
  double get _total => _basePrice + platformFee;

  Future<void> _continueToPay() async {
    final service = widget.service;
    if (service == null) return;
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final success = await _payment.pay();
      if (!mounted) return;
      if (!success) {
        setState(() => _error = 'Payment failed');
        setState(() => _paying = false);
        return;
      }
      final order = _store.createOrder(
        serviceName: service.title,
        creatorName: service.creatorName,
        creatorId: service.creatorId,
        price: service.price,
        platformFee: platformFee,
      );
      _store.updateOrder(order.id, (o) => o.copyWith(status: 'in_progress'));
      _store.addTimelineEvent(order.id, 'payment_received', 'Payment successful. Chat unlocked.');
      if (mounted) context.go('/workspace/${order.id}');
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
        appBar: AppBar(title: const Text('Confirm hire')),
        body: const Center(child: Text('Select a service first')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm hire')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(service.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(service.creatorName, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Service name', service.title),
                    _row('Creator', service.creatorName),
                    _row('Base price', '₹${service.price.toStringAsFixed(0)}'),
                    _row('Platform fee', '₹${platformFee.toStringAsFixed(0)}'),
                    const Divider(height: 24),
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
          Flexible(child: Text(value, textAlign: TextAlign.right, style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null)),
        ],
      ),
    );
  }
}
