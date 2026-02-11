import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/schedule_slot_model.dart';

/// Calendar + time selection. No text negotiation. Max 2 counter proposals.
/// Caller passes proposed/accepted slot and callbacks.
class ScheduleTimePicker extends StatefulWidget {
  const ScheduleTimePicker({
    super.key,
    this.initialDate,
    this.initialTime,
    this.initialDurationMinutes = 60,
    this.counterProposals = 0,
    this.isProvider = false,
    this.proposedSlot,
    this.onPropose,
    this.onAccept,
  });

  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int initialDurationMinutes;
  final int counterProposals;
  final bool isProvider;
  final ScheduleSlotModel? proposedSlot;
  final Future<void> Function(DateTime date, Duration startTime, int durationMinutes)? onPropose;
  final Future<void> Function(DateTime date, Duration startTime, int durationMinutes)? onAccept;

  @override
  State<ScheduleTimePicker> createState() => _ScheduleTimePickerState();
}

class _ScheduleTimePickerState extends State<ScheduleTimePicker> {
  late DateTime _date;
  late TimeOfDay _time;
  late int _durationMinutes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(ScheduleTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposedSlot != widget.proposedSlot ||
        oldWidget.initialDate != widget.initialDate ||
        oldWidget.initialTime != widget.initialTime ||
        oldWidget.initialDurationMinutes != widget.initialDurationMinutes) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _date = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    _time = widget.initialTime ?? const TimeOfDay(hour: 10, minute: 0);
    _durationMinutes = widget.initialDurationMinutes;
    if (widget.proposedSlot != null) {
      _date = widget.proposedSlot!.date;
      _time = TimeOfDay(hour: widget.proposedSlot!.startTime.inHours, minute: widget.proposedSlot!.startTime.inMinutes % 60);
      _durationMinutes = widget.proposedSlot!.durationMinutes;
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (t != null) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPropose = widget.counterProposals < AppConstants.counterProposalsMax;
    final hasProposed = widget.proposedSlot != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Schedule (date + time + duration). Max ${AppConstants.counterProposalsMax} counter proposals.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (hasProposed) ...[
              const SizedBox(height: 8),
              Text(
                'Proposed: ${_formatDate(widget.proposedSlot!.date)} ${widget.proposedSlot!.startTimeLabel} • ${widget.proposedSlot!.durationMinutes} min',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            CalendarDatePicker(
              initialDate: _date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: AppConstants.deadlineMaxDays)),
              onDateChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Start time'),
              subtitle: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: _pickTime,
              ),
            ),
            DropdownButtonFormField<int>(
              value: _durationMinutes,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
              ),
              items: [30, 60, 90, 120].map((m) => DropdownMenuItem(value: m, child: Text('$m min'))).toList(),
              onChanged: (v) => setState(() => _durationMinutes = v ?? 60),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.isProvider && hasProposed) ...[
                  FilledButton(
                    onPressed: _loading ? null : _emitAccept,
                    child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Accept'),
                  ),
                  const SizedBox(width: 12),
                  if (canPropose)
                    OutlinedButton(
                      onPressed: _loading ? null : _emitPropose,
                      child: Text('Counter (${widget.counterProposals}/${AppConstants.counterProposalsMax})'),
                    ),
                ] else if (!widget.isProvider || !hasProposed)
                  FilledButton(
                    onPressed: _loading ? null : _emitPropose,
                    child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Propose slot'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _emitPropose() async {
    final startTime = Duration(hours: _time.hour, minutes: _time.minute);
    final fn = widget.onPropose;
    if (fn == null) return;
    setState(() => _loading = true);
    try {
      await fn(_date, startTime, _durationMinutes);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _emitAccept() async {
    final startTime = Duration(hours: _time.hour, minutes: _time.minute);
    final fn = widget.onAccept;
    if (fn == null) return;
    setState(() => _loading = true);
    try {
      await fn(_date, startTime, _durationMinutes);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
