import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../models/profile_model.dart';
import '../../models/service_model.dart';

/// Alias for backwards compatibility.
typedef ProfileService = MarketplaceProfileService;

class MarketplaceProfileService {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  Future<ProfileModel?> getProfile(String profileId) async {
    try {
      final res = await _client.from('profiles').select().eq('id', profileId).maybeSingle();
      if (res == null) return null;
      return ProfileModel.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// List live provider profiles (for browse). No identity fields exposed.
  Future<List<ProfileModel>> listLiveProfiles({
    String? role,
    int limit = 50,
  }) async {
    try {
      var q = _client.from('profiles').select().eq('is_live', true);
      if (role != null) q = q.eq('role', role);
      final res = await q.order('updated_at', ascending: false).limit(limit);
      return (res as List).map((e) => ProfileModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// My provider profiles (for dashboard).
  Future<List<ProfileModel>> getMyProfiles() async {
    if (_userId == null) return [];
    try {
      final res = await _client.from('profiles').select().eq('user_id', _userId!);
      return (res as List).map((e) => ProfileModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Create or update provider profile (after role paid).
  Future<ProfileModel?> upsertProfile({
    required String role,
    String? displayName,
    String? bio,
  }) async {
    if (_userId == null) return null;
    try {
      await _client.from('profiles').upsert({
        'user_id': _userId!,
        'role': role,
        'display_name': displayName,
        'bio': bio,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,role');
      final list = await _client.from('profiles').select().eq('user_id', _userId!).eq('role', role);
      final first = list is List && list.isNotEmpty ? list.first : null;
      return first != null ? ProfileModel.fromJson(first as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setProfileLive(String profileId, bool live) async {
    await _client.from('profiles').update({
      'is_live': live,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', profileId);
  }

  /// Services for a profile (public: no identity).
  Future<List<ServiceModel>> getServicesForProfile(String profileId) async {
    try {
      final res = await _client
          .from('services')
          .select()
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .order('created_at');
      return (res as List).map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Creator: add service with price only (predefined name).
  Future<ServiceModel?> addCreatorService({
    required String profileId,
    required String name,
    required double priceInr,
  }) async {
    if (_userId == null) return null;
    if (priceInr < AppConstants.minServicePriceInr) return null;
    try {
      final res = await _client.from('services').insert({
        'profile_id': profileId,
        'name': name,
        'price_inr': priceInr,
        'is_active': true,
      }).select().single();
      return ServiceModel.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Videographer/Freelancer: add service with delivery_days, demo_video, addons.
  Future<ServiceModel?> addFullService({
    required String profileId,
    required String name,
    required double priceInr,
    required int deliveryDays,
    String? demoVideoUrl,
    Map<String, dynamic>? addons,
  }) async {
    if (_userId == null) return null;
    if (priceInr < AppConstants.minServicePriceInr) return null;
    try {
      final res = await _client.from('services').insert({
        'profile_id': profileId,
        'name': name,
        'price_inr': priceInr,
        'delivery_days': deliveryDays,
        'demo_video_url': demoVideoUrl,
        'addons_json': addons,
        'is_active': true,
      }).select().single();
      return ServiceModel.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
