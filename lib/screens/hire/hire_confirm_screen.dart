import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../models/service_model.dart';
import '../../services/order_hire_service.dart';

/// Hire confirm: price breakdown, platform fee, delivery days, continue to pay → Razorpay placeholder.
class HireConfirmScreen extends StatefulWidget {
  const HireConfirmScreen({
    super.key,
    required this.serviceId,
  });

  final String serviceId;

  @override
  State<HireConfirmScreen> createState() => _HireConfirmScreenState();
}

class _HireConfirmScreenState extends State<HireConfirmScreen> {
  final OrderHireService _hireService = OrderHireService();

  ServiceModel? _service;
  bool _loading = true;
  bool _creating = false;
  String? _error;

  double get _price => _service?.priceInr ?? 0;
  double get _platformFee => _hireService.platformFeeForPrice(_price);
  double get _total => _price;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    try {
      final res = await Supabase.instance.client
          .from('services')
          .select('*, categories(name)')
          .eq('id', widget.serviceId)
          .eq('is_active', true)
          .maybeSingle();
      setState(() {
        _service = res != null ? ServiceModel.fromJson(res as Map<String, dynamic>) : null;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _continueToPay() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _service == null) {
      setState(() => _error = 'Please log in');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final orderId = await _hireService.createHiringIntent(
        serviceId: _service!.id,
        buyerId: userId,
        price: _service!.priceInr,
      );
      if (!mounted) return;
      if (orderId == null) {
        setState(() => _error = 'Could not create order');
        setState(() => _creating = false);
        return;
      }
      setState(() => _creating = false);
      await _showPaymentPlaceholder(context, orderId);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _creating = false;
      });
    }
  }

  Future<void> _showPaymentPlaceholder(BuildContext context, String orderId) async {
    final pay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment (Razorpay placeholder)'),
        content: const Text(
          'In production this would redirect to Razorpay. Tap below to simulate payment success.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Simulate success'),
          ),
        ],
      ),
    );
    if (!mounted || pay != true) return;
    final success = await _hireService.onPaymentSuccess(orderId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successful')));
        context.go('/order/$orderId/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment confirmation failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm hire')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirm hire')),
        body: const Center(child: Text('Service not found')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm hire')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_service!.name, style: theme.textTheme.titleLarge),
                    if (_service!.description != null && _service!.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_service!.description!, style: theme.textTheme.bodyMedium),
                      ),
                    if (_service!.deliveryDays != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Delivery: ${_service!.deliveryDays} days', style: theme.textTheme.bodySmall),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Price breakdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service'),
                Text('₹${_price.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Platform fee'),
                Text('₹${_platformFee.toStringAsFixed(0)}'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text('₹${_total.toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _creating ? null : _continueToPay,
              child: _creating
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue to pay'),
            ),
          ],
        ),
      ),
    );
  }
}
