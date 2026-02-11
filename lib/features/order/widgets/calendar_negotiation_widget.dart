import 'package:flutter/material.dart';
import '../../../../core/constants.dart';
import '../../../../models/order_model.dart';

/// Calendar-only deadline negotiation. Max 7 days from today. Max 2 counter proposals.
class CalendarNegotiationWidget extends StatefulWidget {
  const CalendarNegotiationWidget({
    super.key,
    required this.order,
    required this.isProvider,
    required this.onAccept,
    required this.onPropose,
  });

  final OrderModel order;
  final bool isProvider;
  final Future<void> Function(DateTime accepted) onAccept;
  final Future<void> Function(DateTime proposed) onPropose;

  @override
  State<CalendarNegotiationWidget> createState() => _CalendarNegotiationWidgetState();
}

class _CalendarNegotiationWidgetState extends State<CalendarNegotiationWidget> {
  DateTime? _selectedDate;
  bool _loading = false;
  String? _error;

  DateTime get _minDate => DateTime.now();
  DateTime get _maxDate => DateTime.now().add(Duration(days: AppConstants.deadlineMaxDays));

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.order.proposedDeadline ?? _minDate.add(const Duration(days: 1));
    if (_selectedDate!.isAfter(_maxDate)) _selectedDate = _maxDate;
    if (_selectedDate!.isBefore(_minDate)) _selectedDate = _minDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPropose = widget.isProvider &&
        widget.order.status == AppConstants.orderPending &&
        widget.order.counterProposals < AppConstants.counterProposalsMax;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Deadline (max ${AppConstants.deadlineMaxDays} days)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (widget.order.proposedDeadline != null) ...[
              const SizedBox(height: 8),
              Text(
                'Proposed: ${_formatDate(widget.order.proposedDeadline!)}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (widget.order.acceptedDeadline != null) ...[
              const SizedBox(height: 4),
              Text(
                'Accepted: ${_formatDate(widget.order.acceptedDeadline!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (canPropose || (widget.isProvider && widget.order.status == AppConstants.orderPending)) ...[
              const SizedBox(height: 16),
              CalendarDatePicker(
                initialDate: _selectedDate ?? _minDate.add(const Duration(days: 1)),
                firstDate: _minDate,
                lastDate: _maxDate,
                onDateChanged: (d) => setState(() => _selectedDate = d),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.isProvider && widget.order.status == AppConstants.orderPending) ...[
                    FilledButton(
                      onPressed: _loading ? null : () => _accept(),
                      child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Accept'),
                    ),
                    const SizedBox(width: 12),
                    if (canPropose)
                      OutlinedButton(
                        onPressed: _loading ? null : () => _propose(),
                        child: Text('Propose new (${widget.order.counterProposals}/${AppConstants.counterProposalsMax})'),
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _accept() async {
    if (_selectedDate == null) return;
    setState(() => _loading = true);
    _error = null;
    try {
      await widget.onAccept(_selectedDate!);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
    setState(() => _loading = false);
  }

  Future<void> _propose() async {
    if (_selectedDate == null) return;
    setState(() => _loading = true);
    _error = null;
    try {
      await widget.onPropose(_selectedDate!);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
    setState(() => _loading = false);
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
