import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/dispute_model.dart';
import '../../services/admin_dispute_service.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  final AdminDisputeService _admin = AdminDisputeService();

  List<DisputeModel> _disputes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _admin.getOpenDisputes();
    if (mounted) setState(() {
      _disputes = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disputes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _disputes.isEmpty
          ? const Center(child: Text('No open disputes'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _disputes.length,
              itemBuilder: (context, i) {
                final d = _disputes[i];
                return Card(
                  child: ListTile(
                    title: Text('Order: ${d.orderId.substring(0, 8)}'),
                    subtitle: Text(d.reason),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'resolve') {
                          final notes = await _showNotesDialog(context);
                          if (notes != null) {
                            await _admin.resolveDispute(d.id, notes);
                            _load();
                          }
                        } else if (v == 'close') {
                          final notes = await _showNotesDialog(context);
                          if (notes != null) {
                            await _admin.closeDispute(d.id, notes);
                            _load();
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'resolve', child: Text('Resolve (unfreeze payout)')),
                        const PopupMenuItem(value: 'close', child: Text('Close dispute')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<String?> _showNotesDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notes'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Resolution notes'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
