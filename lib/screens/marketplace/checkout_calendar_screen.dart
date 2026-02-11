import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../services/marketplace/cart_service.dart';
import '../../services/marketplace/order_service.dart';

class CheckoutCalendarScreen extends StatefulWidget {
  const CheckoutCalendarScreen({super.key});

  @override
  State<CheckoutCalendarScreen> createState() => _CheckoutCalendarScreenState();
}

class _CheckoutCalendarScreenState extends State<CheckoutCalendarScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();

  DateTime? _selectedDate;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Propose deadline')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select delivery deadline (no text negotiation – calendar only).',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text(
              'Max ${AppConstants.deadlineMaxDays} days from today.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            CalendarDatePicker(
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: AppConstants.deadlineMaxDays)),
              onDateChanged: (d) => setState(() => _selectedDate = d),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading || _selectedDate == null ? null : _placeOrder,
              child: _loading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Place order & pay'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedDate == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _cartService.getCartItems();
      if (items.isEmpty) {
        setState(() => _error = 'Cart is empty');
        setState(() => _loading = false);
        return;
      }
      final profileId = items.first.service.profileId;
      final order = await _orderService.createOrderFromCart(
        profileId: profileId,
        proposedDeadline: _selectedDate!,
      );
      if (order != null && mounted) {
        // TODO: Open Razorpay for order.totalInr; on success redirect to order detail
        context.go('/order/${order.id}');
      } else {
        setState(() => _error = 'Could not create order');
      }
    } on DeadlineExceedsMaxException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed');
    }
    setState(() => _loading = false);
  }
}
