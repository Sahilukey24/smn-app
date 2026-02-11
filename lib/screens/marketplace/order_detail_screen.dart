import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../features/order/widgets/calendar_negotiation_widget.dart';
import '../../models/order_model.dart';
import '../../models/order_location_model.dart';
import '../../models/penalty_model.dart';
import '../../models/schedule_slot_model.dart';
import '../../models/order_delivery_model.dart';
import '../../services/delivery_service.dart';
import '../../services/invoice_service.dart';
import '../../services/location_service.dart';
import '../../services/marketplace/order_service.dart';
import '../../services/escrow_service.dart';
import '../../services/schedule_service.dart';
import '../../services/sla_service.dart';
import '../../widgets/location_pin_widget.dart';
import '../../widgets/schedule_time_picker.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  final InvoiceService _invoiceService = InvoiceService();

  OrderModel? _order;
  List<PenaltyModel> _penalties = [];
  List<OrderDeliveryModel> _deliveries = [];
  List<OrderLocationModel> _locations = [];
  bool _loading = true;
  bool _markingReady = false;
  final ScheduleService _scheduleService = ScheduleService();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final order = await _orderService.getOrder(widget.orderId);
      final penalties = order != null ? await SlaService().getPenaltiesForOrder(widget.orderId) : <PenaltyModel>[];
      final deliveries = order != null ? await DeliveryService().getDeliveriesForOrder(widget.orderId) : <OrderDeliveryModel>[];
      final locations = order != null ? await _locationService.getLocationsForOrder(widget.orderId) : <OrderLocationModel>[];
      if (mounted) setState(() {
        _order = order;
        _penalties = penalties;
        _deliveries = deliveries;
        _locations = locations;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _acceptDeadline(DateTime accepted) async {
    await _orderService.acceptDeadline(widget.orderId, accepted);
    _load();
  }

  Future<void> _proposeDeadline(DateTime proposed) async {
    await _orderService.proposeNewDeadline(widget.orderId, proposed);
    _load();
  }

  ScheduleSlotModel? get _proposedSlot {
    final o = _order;
    if (o == null || o.scheduledDate == null || o.startTime == null) return null;
    return ScheduleSlotModel(
      date: o.scheduledDate!,
      startTime: o.startTime!,
      durationMinutes: o.durationMinutes ?? 60,
    );
  }

  Future<void> _proposeSchedule(DateTime date, Duration startTime, int durationMinutes) async {
    await _scheduleService.proposeSlot(orderId: widget.orderId, date: date, startTime: startTime, durationMinutes: durationMinutes);
    _load();
  }

  Future<void> _acceptSchedule(DateTime date, Duration startTime, int durationMinutes) async {
    await _scheduleService.acceptSlot(orderId: widget.orderId, date: date, startTime: startTime, durationMinutes: durationMinutes);
    _load();
  }

  Future<void> _counterProposeSchedule(DateTime date, Duration startTime, int durationMinutes) async {
    await _scheduleService.counterProposeSlot(orderId: widget.orderId, date: date, startTime: startTime, durationMinutes: durationMinutes);
    _load();
  }

  Future<void> _markReadyForDelivery() async {
    setState(() => _markingReady = true);
    await _orderService.markReadyForDelivery(widget.orderId);
    _load();
    setState(() => _markingReady = false);
  }

  Future<void> _downloadInvoice() async {
    if (_order == null) return;
    final file = await _invoiceService.generateOrderInvoice(_order!);
    await _invoiceService.openInvoice(file);
  }

  bool _approving = false;
  Future<void> _approveOrder() async {
    setState(() => _approving = true);
    final ok = await EscrowService().onApprove(widget.orderId);
    if (mounted) _load();
    setState(() => _approving = false);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order approved. Payout released.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading || _order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final o = _order!;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final isProvider = userId == o.providerId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${o.id.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadInvoice,
            tooltip: 'Invoice PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Status'),
              trailing: Chip(label: Text(o.status)),
            ),
          ),
          if (o.status == AppConstants.orderPending && isProvider)
            CalendarNegotiationWidget(
              order: o,
              isProvider: true,
              onAccept: _acceptDeadline,
              onPropose: _proposeDeadline,
            ),
          if (o.status == AppConstants.orderPending && !isProvider)
            CalendarNegotiationWidget(
              order: o,
              isProvider: false,
              onAccept: _acceptDeadline,
              onPropose: _proposeDeadline,
            ),
          if (o.status == AppConstants.orderPending) ...[
            ScheduleTimePicker(
              initialDate: o.scheduledDate,
              initialTime: o.startTime != null ? TimeOfDay(hour: o.startTime!.inHours, minute: o.startTime!.inMinutes % 60) : null,
              initialDurationMinutes: o.durationMinutes ?? 60,
              counterProposals: o.counterProposals,
              isProvider: isProvider,
              proposedSlot: _proposedSlot,
              onPropose: (date, startTime, durationMinutes) {
                if (isProvider && _proposedSlot != null)
                  _counterProposeSchedule(date, startTime, durationMinutes);
                else
                  _proposeSchedule(date, startTime, durationMinutes);
              },
              onAccept: isProvider ? _acceptSchedule : null,
            ),
          ],
          if (o.acceptedScheduledDate != null)
            ListTile(
              title: const Text('Accepted schedule'),
              subtitle: Text(
                '${o.acceptedScheduledDate!.day.toString().padLeft(2, '0')}/${o.acceptedScheduledDate!.month.toString().padLeft(2, '0')}/${o.acceptedScheduledDate!.year} '
                '${o.acceptedStartTime != null ? '${o.acceptedStartTime!.inHours.toString().padLeft(2, '0')}:${(o.acceptedStartTime!.inMinutes % 60).toString().padLeft(2, '0')}' : ''} '
                '• ${o.acceptedDurationMinutes ?? 60} min',
              ),
            ),
          if (o.proposedDeadline != null && o.status != AppConstants.orderPending)
            ListTile(
              title: const Text('Proposed deadline'),
              subtitle: Text(o.proposedDeadline!.toIso8601String().substring(0, 16)),
            ),
          if (o.acceptedDeadline != null)
            ListTile(
              title: const Text('Accepted deadline'),
              subtitle: Text(o.acceptedDeadline!.toIso8601String().substring(0, 16)),
            ),
          ListTile(
            title: const Text('Total'),
            trailing: Text('₹${o.totalInr.toStringAsFixed(0)}'),
          ),
          const Divider(),
          ...o.items.map((i) => ListTile(
                title: Text(i.serviceName),
                subtitle: Text('₹${i.priceInr.toStringAsFixed(0)} × ${i.quantity}'),
              )),
          if (isProvider && o.status == AppConstants.orderInProgress && o.readyForDeliveryAt == null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton.icon(
                onPressed: _markingReady ? null : _markReadyForDelivery,
                icon: _markingReady ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
                label: const Text('Mark Ready for Delivery'),
              ),
            ),
          if (o.canUploadDelivery && isProvider)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.icon(
                onPressed: () => context.push('/order/${widget.orderId}/delivery'),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload delivery (MP4/MP3/PDF)'),
              ),
            ),
          if (!isProvider && o.status == AppConstants.orderDelivered)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.icon(
                onPressed: _approving ? null : _approveOrder,
                icon: _approving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle),
                label: const Text('Approve & complete'),
              ),
            ),
          if (!isProvider && (o.status == AppConstants.orderDelivered || o.status == AppConstants.orderRevision))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await context.push<bool>('/order/${widget.orderId}/revision');
                  if (result == true) _load();
                },
                icon: const Icon(Icons.edit_note),
                label: Text('Request revision${o.revisionCount > 0 ? " (${o.revisionCount} so far)" : ""}'),
              ),
            ),
          if (_deliveries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Deliveries', style: theme.textTheme.titleSmall),
            ..._deliveries.map((d) => ListTile(
                  title: Text('${d.fileType?.toUpperCase() ?? "File"} • ${d.fileSizeBytes != null ? "${(d.fileSizeBytes! / 1024).round()} KB" : ""}'),
                  subtitle: Text(d.createdAt.toIso8601String().substring(0, 16)),
                )),
          ],
          if (_penalties.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Penalties (2%/day, max 10%, grace 6h)', style: theme.textTheme.titleSmall),
            ..._penalties.map((p) => ListTile(
                  title: Text('${p.penaltyPercent.toStringAsFixed(1)}% • ₹${p.penaltyAmountInr.toStringAsFixed(0)}'),
                  subtitle: Text('${p.daysLate} day(s) late'),
                )),
          ],
          if (o.isChatUnlocked) ...[
            LocationPinWidget(
              orderId: widget.orderId,
              locations: _locations,
              onLocationShared: _load,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton.icon(
                onPressed: () => context.push('/order/${widget.orderId}/workspace'),
                icon: const Icon(Icons.chat),
                label: const Text('Open workspace (Chat & Delivery)'),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/dispute/${widget.orderId}'),
              icon: const Icon(Icons.warning_amber_outlined),
              label: const Text('Raise dispute'),
            ),
          ),
        ],
      ),
    );
  }
}
