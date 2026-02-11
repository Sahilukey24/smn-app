import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors.dart';
import '../../core/file_rules.dart';
import '../../services/delivery_service.dart';
import '../../services/escrow_service.dart';
import '../../services/mvp_order_service.dart';
import '../../services/order_finance_service.dart';
import '../../services/order_timeline_service.dart';
import '../../services/order_service.dart';

/// Order delivery: file picker, message, upload then mark status = delivered.
class OrderDeliveryUploadScreen extends StatefulWidget {
  const OrderDeliveryUploadScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDeliveryUploadScreen> createState() => _OrderDeliveryUploadScreenState();
}

class _OrderDeliveryUploadScreenState extends State<OrderDeliveryUploadScreen> {
  final DeliveryService _delivery = DeliveryService();
  final OrderService _orderService = OrderService();

  File? _file;
  String? _selectedExt;
  final _messageController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _error = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mp3', 'pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final ext = result.files.single.extension?.toLowerCase() ?? '';
    if (ext.isEmpty || !FileRules.isAllowedExtension(ext)) {
      setState(() => _error = 'Only MP4, MP3, PDF allowed');
      return;
    }
    setState(() {
      _file = File(path);
      _selectedExt = ext;
    });
  }

  Future<void> _upload() async {
    if (_file == null || _selectedExt == null) {
      setState(() => _error = 'Select a file');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _delivery.validateFile(_file!, _selectedExt!);
      await _delivery.uploadDelivery(
        orderId: widget.orderId,
        file: _file!,
        fileType: _selectedExt!,
      );
      final finance = await OrderFinanceService().getFinanceForOrder(widget.orderId);
      if (finance == null) {
        await MvpOrderService().markDelivered(widget.orderId);
      } else {
        await _orderService.markDelivered(widget.orderId);
        await OrderFinanceService().markDelivered(widget.orderId);
        await EscrowService().markDelivered(widget.orderId);
        await OrderTimelineService().addEvent(widget.orderId, 'delivered', 'Delivered', 'Creator uploaded delivery.');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivered')));
        context.pop();
      }
    } on InvalidFileTypeException {
      setState(() => _error = 'Only MP4, MP3, PDF allowed');
    } on FileTooLargeException catch (e) {
      setState(() => _error = e.message);
    } on DeliveryNotReadyException {
      setState(() => _error = 'Not ready for delivery');
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Upload delivery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Allowed: ${FileRules.allowedExtensionsDisplay}. Limits: MP4 200MB, MP3 50MB, PDF 20MB.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_file == null ? 'Select file' : _file!.path.split(RegExp(r'[/\\]')).last),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading || _file == null ? null : _upload,
              child: _loading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Upload & mark delivered'),
            ),
          ],
        ),
      ),
    );
  }
}
