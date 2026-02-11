import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/errors.dart';
import '../models/order_model.dart';
import '../models/schedule_slot_model.dart';

/// Schedule: calendar + time selection. No text negotiation. Max 2 counter proposals.
/// Store date + start_time + duration.
class ScheduleService {
  ScheduleService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Propose slot (buyer). Date + start time + duration.
  Future<bool> proposeSlot({
    required String orderId,
    required DateTime date,
    required Duration startTime,
    required int durationMinutes,
  }) async {
    try {
      final timeStr = '${startTime.inHours.toString().padLeft(2, '0')}:${(startTime.inMinutes % 60).toString().padLeft(2, '0')}:00';
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _client.from('orders').update({
        'scheduled_date': dateStr,
        'start_time': timeStr,
        'duration_minutes': durationMinutes,
        'last_proposal_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Provider: accept slot (store as accepted_*).
  Future<bool> acceptSlot({
    required String orderId,
    required DateTime date,
    required Duration startTime,
    required int durationMinutes,
  }) async {
    try {
      final timeStr = '${startTime.inHours.toString().padLeft(2, '0')}:${(startTime.inMinutes % 60).toString().padLeft(2, '0')}:00';
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _client.from('orders').update({
        'accepted_scheduled_date': dateStr,
        'accepted_start_time': timeStr,
        'accepted_duration_minutes': durationMinutes,
        'status': AppConstants.orderInProgress,
        'chat_unlocked_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Provider: counter-propose (max 2).
  Future<bool> counterProposeSlot({
    required String orderId,
    required DateTime date,
    required Duration startTime,
    required int durationMinutes,
  }) async {
    final order = await _client.from('orders').select('counter_proposals').eq('id', orderId).maybeSingle();
    if (order == null) return false;
    final count = (order['counter_proposals'] as num?)?.toInt() ?? 0;
    if (count >= AppConstants.counterProposalsMax) {
      throw CounterProposalsExceededException();
    }
    final timeStr = '${startTime.inHours.toString().padLeft(2, '0')}:${(startTime.inMinutes % 60).toString().padLeft(2, '0')}:00';
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await _client.from('orders').update({
      'scheduled_date': dateStr,
      'start_time': timeStr,
      'duration_minutes': durationMinutes,
      'counter_proposals': count + 1,
      'last_proposal_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
    return true;
  }

  /// Get proposed slot from order row.
  ScheduleSlotModel? getProposedSlotFromOrder(OrderModel order) {
    // Order may have proposed_deadline or new scheduled_date + start_time
    final date = order.proposedDeadline;
    if (date == null) return null;
    // If we have start_time/duration in order we need to fetch from DB; for now derive from proposedDeadline
    return ScheduleSlotModel(
      date: DateTime(date.year, date.month, date.day),
      startTime: Duration(hours: date.hour, minutes: date.minute),
      durationMinutes: 60,
    );
  }

  /// Get accepted slot from order (scheduled_date/start_time/duration or accepted_*).
  Future<ScheduleSlotModel?> getAcceptedSlot(String orderId) async {
    final res = await _client.from('orders').select('accepted_scheduled_date, accepted_start_time, accepted_duration_minutes').eq('id', orderId).maybeSingle();
    if (res == null) return null;
    final dateStr = res['accepted_scheduled_date'] as String?;
    final timeStr = res['accepted_start_time'] as String?;
    final dur = (res['accepted_duration_minutes'] as num?)?.toInt();
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    Duration start = Duration.zero;
    if (timeStr != null) {
      final parts = timeStr.split(':');
      start = Duration(hours: int.tryParse(parts[0]) ?? 0, minutes: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    }
    return ScheduleSlotModel(date: date, startTime: start, durationMinutes: dur ?? 60);
  }

  /// Get proposed slot from order (scheduled_date, start_time, duration_minutes).
  Future<ScheduleSlotModel?> getProposedSlot(String orderId) async {
    final res = await _client.from('orders').select('scheduled_date, start_time, duration_minutes').eq('id', orderId).maybeSingle();
    if (res == null) return null;
    final dateStr = res['scheduled_date'] as String?;
    final timeStr = res['start_time'] as String?;
    final dur = (res['duration_minutes'] as num?)?.toInt();
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    Duration start = Duration.zero;
    if (timeStr != null) {
      final parts = timeStr.split(':');
      start = Duration(hours: int.tryParse(parts[0]) ?? 0, minutes: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    }
    return ScheduleSlotModel(date: date, startTime: start, durationMinutes: dur ?? 60);
  }
}
