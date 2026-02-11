import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../models/order_delivery_model.dart';
import '../../services/chat_service.dart';
import '../../services/delivery_service.dart';
import '../../services/order_timeline_service.dart';
import '../../models/order_model.dart';
import '../../services/marketplace/order_service.dart';

/// Order workspace: Chat, Delivery, Timeline tabs. Buyer + creator + freelancer.
class OrderWorkspaceScreen extends StatefulWidget {
  const OrderWorkspaceScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderWorkspaceScreen> createState() => _OrderWorkspaceScreenState();
}

class _OrderWorkspaceScreenState extends State<OrderWorkspaceScreen> with SingleTickerProviderStateMixin {
  final ChatService _chat = ChatService();
  final DeliveryService _delivery = DeliveryService();
  final OrderTimelineService _timeline = OrderTimelineService();
  final OrderService _orderService = OrderService();

  late TabController _tabController;
  Map<String, dynamic>? _room;
  List<Map<String, dynamic>> _messages = [];
  List<OrderDeliveryModel> _deliveries = [];
  List<Map<String, dynamic>> _timelineEvents = [];
  OrderModel? _order;
  bool _loading = true;
  final _messageController = TextEditingController();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final order = await _orderService.getOrder(widget.orderId);
      final room = await _chat.getRoomByOrderId(widget.orderId);
      List<Map<String, dynamic>> messages = [];
      if (room != null) {
        messages = await _chat.getMessages(room['id'] as String);
      }
      final deliveries = await _delivery.getDeliveriesForOrder(widget.orderId);
      final events = await _timeline.getTimelineForOrder(widget.orderId);
      if (mounted) setState(() {
        _order = order;
        _room = room;
        _messages = messages;
        _deliveries = deliveries;
        _timelineEvents = events;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _room == null) return;
    final roomId = _room!['id'] as String;
    final sent = await _chat.sendMessage(roomId: roomId, content: text);
    if (sent != null) {
      _messageController.clear();
      setState(() => _messages = [..._messages, sent]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Workspace #${widget.orderId.substring(0, 8)}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Workspace #${widget.orderId.substring(0, 8)}'),
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
          _buildChatTab(theme),
          _buildDeliveryTab(theme),
          _buildTimelineTab(theme),
        ],
      ),
    );
  }

  Widget _buildChatTab(ThemeData theme) {
    final isBuyer = _order != null && _order!.buyerId == _userId;
    final isProvider = _order != null && _order!.providerId == _userId;
    final chatUnlocked = _order?.chatUnlockedAt != null;
    if (!chatUnlocked) {
      return Center(
        child: Text(
          'Chat unlocks after payment.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }
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
                      if (m['attachment_url'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '📎 Attachment',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
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
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTab(ThemeData theme) {
    final isProvider = _order != null && _order!.providerId == _userId;
    final canUpload = isProvider && _order?.readyForDeliveryAt != null;
    final isBuyer = _order != null && _order!.buyerId == _userId;
    final status = _order?.status ?? '';
    final showApprove = isBuyer && status == AppConstants.orderDelivered;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canUpload)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: () async {
                await context.push('/order/${widget.orderId}/delivery');
                _load();
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload delivery'),
            ),
          ),
        if (showApprove)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: () async {
                await context.push('/order/${widget.orderId}/approve');
                _load();
              },
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
                title: Text('${d.fileType?.toUpperCase() ?? 'File'} • ${d.fileSizeBytes != null ? "${(d.fileSizeBytes! / 1024).round()} KB" : ""}'),
                subtitle: Text(d.createdAt.toIso8601String().substring(0, 16)),
                trailing: isBuyer
                    ? TextButton(
                        onPressed: () async {
                          final url = await _delivery.getSignedDownloadUrl(d.filePath ?? '');
                          if (url != null && context.mounted) {
                            // Could launch url in browser
                          }
                        },
                        child: const Text('Download'),
                      )
                    : null,
              )),
      ],
    );
  }

  Widget _buildTimelineTab(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timelineEvents.length,
      itemBuilder: (context, i) {
        final e = _timelineEvents[_timelineEvents.length - 1 - i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(e['title'] as String? ?? e['event_type'] ?? ''),
            subtitle: Text(e['description'] as String? ?? ''),
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
