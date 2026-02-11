import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/service_model.dart';
import '../../services/mvp_order_service.dart';

/// MVP: Show service, price + platform fee, "Hire & Continue to Pay" → create order → payment screen.
class HireServiceScreen extends StatefulWidget {
  const HireServiceScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  State<HireServiceScreen> createState() => _HireServiceScreenState();
}

class _HireServiceScreenState extends State<HireServiceScreen> {
  final MvpOrderService _mvpOrder = MvpOrderService();

  ServiceModel? _service;
  bool _loading = true;
  bool _creating = false;
  String? _error;

  double get _price => _service?.priceInr ?? 0;
  double get _platformFee => _mvpOrder.platformFeeForPrice(_price);
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

  Future<void> _hireAndContinueToPay() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _error = 'Please log in');
      return;
    }
    if (_service == null) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final orderId = await _mvpOrder.createOrder(
        buyerId: userId,
        serviceId: _service!.id,
        price: _service!.priceInr,
      );
      if (!mounted) return;
      if (orderId == null) {
        setState(() {
          _error = 'Could not create order';
          _creating = false;
        });
        return;
      }
      setState(() => _creating = false);
      context.push('/order/$orderId/payment');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hire')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hire')),
        body: const Center(child: Text('Service not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_service!.name)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _service!.name,
            style: theme.textTheme.headlineSmall,
          ),
          if (_service!.description != null) ...[
            const SizedBox(height: 8),
            Text(_service!.description!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Price breakdown', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Service price'),
                      Text('₹${_price.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Platform fee (12%)'),
                      Text('₹${_platformFee.toStringAsFixed(0)}'),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleMedium),
                      Text('₹${_total.toStringAsFixed(0)}', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _creating ? null : _hireAndContinueToPay,
            child: _creating
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Hire & Continue to Pay'),
          ),
        ],
      ),
    );
  }
}
