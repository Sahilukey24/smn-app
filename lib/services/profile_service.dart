import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

/// CRUD for profiles table and role checks.
class ProfileService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Profile?> getProfile(String userId) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res == null) return null;
      return Profile.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<Profile?> getCurrentProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return getProfile(uid);
  }

  Future<void> updateRole(String userId, String role) async {
    await _client.from('profiles').update({
      'role': role,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateProfile({
    required String userId,
    String? username,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<List<Profile>> searchByUsername(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await _client
        .from('profiles')
        .select()
        .ilike('username', '%${query.trim()}%')
        .limit(20);
    return (res as List)
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// True if current user has admin or member role (can post).
  Future<bool> canPost() async {
    final p = await getCurrentProfile();
    return p != null && (p.role == 'admin' || p.role == 'member');
  }

  /// True if current user is admin.
  Future<bool> isAdmin() async {
    final p = await getCurrentProfile();
    return p != null && p.role == 'admin';
  }
}
