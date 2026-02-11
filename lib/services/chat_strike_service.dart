import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// Strike system for chat: block numbers, emails, links; whitelist punctuation.
/// On violation, call [recordStrike]. When [getStrikeCount] >= [AppConstants.chatMaxStrikesBeforeAction], take action.
class ChatStrikeService {
  ChatStrikeService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns current strike count for user in room (0 if no row).
  Future<int> getStrikeCount({required String userId, required String roomId}) async {
    try {
      final res = await _client
          .from('chat_strikes')
          .select('strike_count')
          .eq('user_id', userId)
          .eq('room_id', roomId)
          .maybeSingle();
      return (res?['strike_count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Increment strike for user in room. Creates row if needed. Sets last_strike_at.
  /// Requires RLS policy allowing insert/update for room parties.
  Future<void> recordStrike({required String userId, required String roomId}) async {
    try {
      final existing = await _client
          .from('chat_strikes')
          .select('id, strike_count')
          .eq('user_id', userId)
          .eq('room_id', roomId)
          .maybeSingle();
      final now = DateTime.now().toIso8601String();
      if (existing != null) {
        final count = ((existing['strike_count'] as num?)?.toInt() ?? 0) + 1;
        await _client.from('chat_strikes').update({
          'strike_count': count,
          'last_strike_at': now,
          'updated_at': now,
        }).eq('user_id', userId).eq('room_id', roomId);
      } else {
        await _client.from('chat_strikes').insert({
          'user_id': userId,
          'room_id': roomId,
          'strike_count': 1,
          'last_strike_at': now,
        });
      }
    } catch (_) {}
  }

  bool hasReachedMax(int strikeCount) =>
      strikeCount >= AppConstants.chatMaxStrikesBeforeAction;
}
