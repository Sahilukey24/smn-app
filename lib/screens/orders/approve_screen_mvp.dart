import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_repository.dart';

/// Product-first: Approve button → order completed, add amount to creator earnings.
class ApproveScreenMvp extends StatefulWidget {
  const ApproveScreenMvp({super.key, required this.orderId});

  final String orderId;

  @override
  State<ApproveScreenMvp> createState() => _ApproveScreenMvpState();
}

class _ApproveScreenMvpState extends State<ApproveScreenMvp> {
  final _repo = MockRepository.instance;
  MockOrderModel? _order;
  bool _approving = false;

  @override
  void initState() {
    super.initState();
    _order = _repo.getOrderById(widget.orderId);
  }

  Future<void> _approve() async {
    if (_order == null || _order!.status != 'delivered') return;
    setState(() => _approving = true);
    _repo.updateOrderStatus(widget.orderId, 'completed');
    _repo.addToCreatorEarnings(_order!.creatorId, _order!.price);
    _repo.addTimelineEvent(widget.orderId, 'approved', 'Order approved. Creator earnings updated.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order approved. Creator earnings updated.')));
      context.go('/workspace/${widget.orderId}');
    }
    setState(() => _approving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approve')),
        body: const Center(child: Text('Order not found')),
      );
    }
    final status = _order!.status;
    final canApprove = status == 'delivered';

    return Scaffold(
      appBar: AppBar(title: Text('Approve order #${_order!.id.substring(0, 8)}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Amount: ₹${_order!.price.toStringAsFixed(0)}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 32),
            if (canApprove)
              FilledButton(
                onPressed: _approving ? null : _approve,
                child: _approving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Approve & complete'),
              )
            else
              Text('Order must be delivered before you can approve.', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
