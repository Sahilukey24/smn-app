import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_repository.dart';

/// Product-first workspace: Chat, Delivery, Timeline. Creator uploads; Business approves.
class WorkspaceScreenMvp extends StatefulWidget {
  const WorkspaceScreenMvp({super.key, required this.orderId, this.currentUserId});

  final String orderId;
  /// Mock: pass 'buyer-1' for business, order.creatorId for creator. Defaults to buyer.
  final String? currentUserId;

  @override
  State<WorkspaceScreenMvp> createState() => _WorkspaceScreenMvpState();
}

class _WorkspaceScreenMvpState extends State<WorkspaceScreenMvp> with SingleTickerProviderStateMixin {
  final _repo = MockRepository.instance;
  final _messageController = TextEditingController();

  late TabController _tabController;
  MockOrderModel? _order;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _deliveries = [];
  List<Map<String, dynamic>> _timeline = [];
  String? _currentUserIdOverride;

  String get _userId => _currentUserIdOverride ?? widget.currentUserId ?? _order?.buyerId ?? 'buyer-1';

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
    setState(() {
      _order = _repo.getOrderById(widget.orderId);
      _messages = _repo.getMessages(widget.orderId);
      _deliveries = _repo.getDeliveries(widget.orderId);
      _timeline = _repo.getTimeline(widget.orderId);
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _repo.sendMessage(widget.orderId, _userId, text);
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
    final isBuyer = _order!.buyerId == _userId;
    final isCreator = _order!.creatorId == _userId;
    final showApprove = isBuyer && _order!.status == 'delivered';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order!.id.substring(0, 8)}'),
        actions: [
          if (_order != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentUserIdOverride = _userId == _order!.buyerId ? _order!.creatorId : _order!.buyerId;
                  _load();
                });
              },
              child: Text(_userId == _order!.buyerId ? 'View as creator' : 'View as buyer'),
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
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final isMe = m['sender_id'] == _userId;
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
                      Text(m['content'] as String? ?? ''),
                      Text(
                        _formatTime(m['created_at']),
                        style: theme.textTheme.labelSmall,
                      ),
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
              onPressed: () => context.push('/mvp/delivery/${widget.orderId}').then((_) => _load()),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload delivery'),
            ),
          ),
        if (showApprove)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: () => context.push('/mvp/approve/${widget.orderId}').then((_) => _load()),
              icon: const Icon(Icons.check_circle),
              label: const Text('Approve & complete'),
            ),
          ),
        Text('Deliveries (${_deliveries.length})', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_deliveries.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('No deliveries yet.'))
        else
          ..._deliveries.map((d) => ListTile(
                title: Text(d['file_url'] as String? ?? 'File'),
                subtitle: Text(_formatTime(d['created_at'])),
              )),
      ],
    );
  }

  Widget _timelineTab(ThemeData theme) {
    final list = _timeline.reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(e['event'] as String? ?? ''),
            subtitle: Text(e['message'] as String? ?? ''),
            trailing: Text(_formatTime(e['created_at']), style: theme.textTheme.labelSmall),
          ),
        );
      },
    );
  }

  String _formatTime(dynamic v) {
    if (v == null) return '';
    final dt = v is String ? DateTime.tryParse(v) : null;
    return dt != null ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}' : '';
  }
}
