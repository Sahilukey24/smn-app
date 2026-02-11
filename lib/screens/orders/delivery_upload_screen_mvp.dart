import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_repository.dart';

/// Product-first: upload file (mock), mark delivered.
class DeliveryUploadScreenMvp extends StatefulWidget {
  const DeliveryUploadScreenMvp({super.key, required this.orderId});

  final String orderId;

  @override
  State<DeliveryUploadScreenMvp> createState() => _DeliveryUploadScreenMvpState();
}

class _DeliveryUploadScreenMvpState extends State<DeliveryUploadScreenMvp> {
  final _repo = MockRepository.instance;
  String? _fileLabel;
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    setState(() => _uploading = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final label = 'delivery_${DateTime.now().millisecondsSinceEpoch}.pdf';
    _repo.addDelivery(widget.orderId, label);
    _repo.updateOrderStatus(widget.orderId, 'delivered');
    _repo.addTimelineEvent(widget.orderId, 'delivered', 'Creator uploaded delivery.');
    setState(() {
      _fileLabel = label;
      _uploading = false;
    });
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
              onPressed: _uploading ? null : _pickAndUpload,
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
