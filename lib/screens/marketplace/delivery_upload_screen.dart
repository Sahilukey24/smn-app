import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/errors.dart';
import '../../core/file_rules.dart';
import '../../services/delivery_service.dart';

class DeliveryUploadScreen extends StatefulWidget {
  const DeliveryUploadScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<DeliveryUploadScreen> createState() => _DeliveryUploadScreenState();
}

class _DeliveryUploadScreenState extends State<DeliveryUploadScreen> {
  final DeliveryService _delivery = DeliveryService();

  File? _file;
  String? _selectedExt;
  bool _loading = false;
  String? _error;

  List<String> get _extensions => AppConstants.allowedDeliveryExtensions;

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
      setState(() => _error = 'Select a file and type');
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded')));
        context.pop();
      }
    } on InvalidFileTypeException {
      setState(() => _error = 'Only MP4, MP3, PDF allowed');
    } on FileTooLargeException catch (e) {
      setState(() => _error = e.message);
    } on DeliveryNotReadyException {
      setState(() => _error = 'Mark Ready for Delivery first');
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
            DropdownButtonFormField<String>(
              value: _selectedExt,
              decoration: const InputDecoration(
                labelText: 'File type',
                border: OutlineInputBorder(),
              ),
              items: _extensions.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _selectedExt = v),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_file == null ? 'Select file' : _file!.path.split(RegExp(r'[/\\]')).last),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading || _file == null ? null : _upload,
              child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
