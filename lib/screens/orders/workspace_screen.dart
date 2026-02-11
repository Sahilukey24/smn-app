import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_order_store.dart';
import '../../models/mock_order.dart';

/// Workspace: Chat, Delivery, Timeline. Mock messages. Upload (mock), mark delivered. Buyer: Approve & Complete.
class OrdersWorkspaceScreen extends StatefulWidget {
  const OrdersWorkspaceScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrdersWorkspaceScreen> createState() => _OrdersWorkspaceScreenState();
}

class _OrdersWorkspaceScreenState extends State<OrdersWorkspaceScreen> with SingleTickerProviderStateMixin {
  final _store = MockOrderStore.instance;
  final _messageController = TextEditingController();

  late TabController _tabController;
  MockOrder? _order;
  String _currentUserId = 'business-1';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() => _order = _store.getOrderById(widget.orderId));
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _store.addMessage(widget.orderId, _currentUserId, text);
    _messageController.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workspace')),
        body: const Center(child: Text('Order not found')),
      );
    }
    final isBuyer = _order!.buyerId == _currentUserId;
    final isCreator = _order!.creatorId == _currentUserId;
    final showApprove = isBuyer && _order!.status == 'delivered';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order • ${_order!.serviceName}'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentUserId = _currentUserId == _order!.buyerId ? _order!.creatorId : _order!.buyerId;
                _load();
              });
            },
            child: Text(_currentUserId == _order!.buyerId ? 'View as creator' : 'View as buyer'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.upload_file), text: 'Delivery'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _chatTab(theme),
          _deliveryTab(theme, isCreator, showApprove),
          _timelineTab(theme),
        ],
      ),
    );
  }

  Widget _chatTab(ThemeData theme) {
    final messages = _order?.messages ?? [];
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final m = messages[i];
              final isMe = m.senderId == _currentUserId;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.content),
                      Text(_formatTime(m.createdAt), style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(hintText: 'Message', border: OutlineInputBorder()),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _sendMessage, icon: const Icon(Icons.send)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deliveryTab(ThemeData theme, bool isCreator, bool showApprove) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isCreator && _order!.status == 'in_progress')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: () => context.push('/delivery/${widget.orderId}').then((_) => _load()),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload delivery'),
            ),
          ),
        if (showApprove)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: () => context.push('/approve/${widget.orderId}').then((_) => _load()),
              icon: const Icon(Icons.check_circle),
              label: const Text('Approve & Complete'),
            ),
          ),
        Text('Delivery', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_order!.deliveredFile == null)
          const Padding(padding: EdgeInsets.all(16), child: Text('No delivery yet.'))
        else
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(_order!.deliveredFile!),
          ),
      ],
    );
  }

  Widget _timelineTab(ThemeData theme) {
    final list = _order?.timeline ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[list.length - 1 - i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(e.event),
            subtitle: Text(e.message),
            trailing: Text(_formatTime(e.createdAt), style: theme.textTheme.labelSmall),
          ),
        );
      },
    );
  }

  String _formatTime(String v) {
    final dt = DateTime.tryParse(v);
    return dt != null ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}' : '';
  }
}
