import 'package:supabase_flutter/supabase_flutter.dart';

/// Order chat: get room by order_id, list messages, send message (optional attachment).
class ChatService {
  ChatService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Get chat room for order (one room per order).
  Future<Map<String, dynamic>?> getRoomByOrderId(String orderId) async {
    try {
      final res = await _client
          .from('chat_rooms')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();
      return res as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// List messages for room, oldest first.
  Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    try {
      final res = await _client
          .from('chat_messages')
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (_) {
      return [];
    }
  }

  /// Send a message. Optional [attachmentUrl] (e.g. Supabase storage path or public URL).
  Future<Map<String, dynamic>?> sendMessage({
    required String roomId,
    required String content,
    String? attachmentUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final data = <String, dynamic>{
        'room_id': roomId,
        'sender_id': userId,
        'content': content,
      };
      if (attachmentUrl != null) data['attachment_url'] = attachmentUrl;
      final res = await _client.from('chat_messages').insert(data).select().single();
      return res as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Realtime subscription for new messages in a room.
  SupabaseRealtimeChannel subscribeToMessages(String roomId, void Function(Map<String, dynamic>) onMessage) {
    return _client
        .channel('chat_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord != null) onMessage(Map<String, dynamic>.from(newRecord));
          },
        )
        .subscribe();
  }
}
