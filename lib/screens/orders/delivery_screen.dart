import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_order_store.dart';

/// Mock delivery upload: tap to simulate upload and mark delivered.
class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _store = MockOrderStore.instance;
  bool _uploading = false;

  Future<void> _uploadAndMarkDelivered() async {
    setState(() => _uploading = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final fileLabel = 'delivery_${DateTime.now().millisecondsSinceEpoch}.pdf';
    _store.markDelivered(widget.orderId, fileLabel);
    setState(() => _uploading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivered')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload delivery')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tap to simulate file upload and mark as delivered.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _uploading ? null : _uploadAndMarkDelivered,
              child: _uploading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Upload & mark delivered'),
            ),
          ],
        ),
      ),
    );
  }
}
