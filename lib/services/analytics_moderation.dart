import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/manual_post_model.dart';

/// Hybrid analytics: API + manual. Manual posts require admin approval.
class AnalyticsModerationService {
  AnalyticsModerationService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  String? get _userId => _client.auth.currentUser?.id;

  /// Creator: submit manual post for approval.
  Future<ManualPostModel?> submitManualPost({
    required String profileId,
    String? postUrl,
    int? views,
    int? likes,
    int? comments,
    int? shares,
  }) async {
    if (_userId == null) return null;
    try {
      final res = await _client.from('manual_posts').insert({
        'profile_id': profileId,
        'post_url': postUrl,
        'views': views,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'status': 'pending',
      }).select().single();
      return ManualPostModel.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<ManualPostModel>> getManualPostsForProfile(String profileId) async {
    final res = await _client.from('manual_posts').select().eq('profile_id', profileId).order('created_at', ascending: false);
    return (res as List).map((e) => ManualPostModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Pending posts (for admin list).
  Future<List<ManualPostModel>> getPendingManualPosts() async {
    final res = await _client.from('manual_posts').select().eq('status', 'pending').order('created_at', ascending: false);
    return (res as List).map((e) => ManualPostModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
