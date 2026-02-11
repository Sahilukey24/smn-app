/// Proposed or accepted slot: date + start_time + duration. No text negotiation.
class ScheduleSlotModel {
  const ScheduleSlotModel({
    required this.date,
    required this.startTime,
    required this.durationMinutes,
  });

  factory ScheduleSlotModel.fromJson(Map<String, dynamic> json) {
    return ScheduleSlotModel(
      date: DateTime.parse(json['date'] as String),
      startTime: _parseTime(json['start_time']),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
    );
  }

  final DateTime date;
  final Duration startTime; // time of day as Duration since midnight
  final int durationMinutes;

  Map<String, dynamic> toJson() => {
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'start_time': '${startTime.inHours.toString().padLeft(2, '0')}:${(startTime.inMinutes % 60).toString().padLeft(2, '0')}:00',
        'duration_minutes': durationMinutes,
      };

  static Duration _parseTime(dynamic v) {
    if (v == null) return Duration.zero;
    if (v is String) {
      final parts = v.split(':');
      final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return Duration(hours: h, minutes: m);
    }
    return Duration.zero;
  }

  String get startTimeLabel {
    final h = startTime.inHours;
    final m = startTime.inMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
