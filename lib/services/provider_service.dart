import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/profile_model.dart';

/// Provider onboarding: create/update profile, link social, set service types (max 4).
/// Uses tables: profiles, provider_social, profile_predefined_services.
class ProviderService {
  ProviderService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  String? get _userId => _client.auth.currentUser?.id;

  /// Create provider profile (after role selected: creator/videographer/freelancer).
  Future<ProfileModel?> createProviderProfile({
    required String role,
    required String displayName,
    required String bio,
    double? basePriceInr,
    int? deliveryDays,
    List<Map<String, String>>? portfolioLinks,
  }) async {
    if (_userId == null) return null;
    if (bio.length < AppConstants.providerBioMinLength || bio.length > AppConstants.providerBioMaxLength) {
      return null;
    }
    try {
      final res = await _client.from('profiles').insert({
        'user_id': _userId!,
        'role': role,
        'display_name': displayName,
        'bio': bio,
        'base_price_inr': basePriceInr,
        'default_delivery_days': deliveryDays,
        'portfolio_links': portfolioLinks ?? [],
        'is_live': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();
      return ProfileModel.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Update provider profile (display name, bio, base price, delivery days, portfolio).
  Future<ProfileModel?> updateProviderProfile({
    required String profileId,
    String? displayName,
    String? bio,
    double? basePriceInr,
    int? deliveryDays,
    List<Map<String, String>>? portfolioLinks,
  }) async {
    if (_userId == null) return null;
    if (bio != null && (bio.length < AppConstants.providerBioMinLength || bio.length > AppConstants.providerBioMaxLength)) {
      return null;
    }
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (displayName != null) updates['display_name'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (basePriceInr != null) updates['base_price_inr'] = basePriceInr;
      if (deliveryDays != null) updates['default_delivery_days'] = deliveryDays;
      if (portfolioLinks != null) updates['portfolio_links'] = portfolioLinks;

      await _client.from('profiles').update(updates).eq('id', profileId).eq('user_id', _userId!);
      final res = await _client.from('profiles').select().eq('id', profileId).maybeSingle();
      return res != null ? ProfileModel.fromJson(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  /// Link Instagram and YouTube (writes to profiles + provider_social).
  Future<bool> linkSocialAccounts({
    required String profileId,
    String? instagramHandle,
    String? youtubeHandle,
  }) async {
    if (_userId == null) return false;
    try {
      await _client.from('profiles').update({
        'instagram_handle': instagramHandle,
        'youtube_channel_id': youtubeHandle,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', profileId).eq('user_id', _userId!);

      if (instagramHandle != null && instagramHandle.isNotEmpty) {
        await _client.from('provider_social').upsert({
          'profile_id': profileId,
          'platform': 'instagram',
          'handle_or_url': instagramHandle,
        }, onConflict: 'profile_id,platform');
      }
      if (youtubeHandle != null && youtubeHandle.isNotEmpty) {
        await _client.from('provider_social').upsert({
          'profile_id': profileId,
          'platform': 'youtube',
          'handle_or_url': youtubeHandle,
        }, onConflict: 'profile_id,platform');
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Set up to 4 predefined service types for this profile. Replaces existing.
  Future<bool> setServices({
    required String profileId,
    required List<String> predefinedServiceIds,
  }) async {
    if (_userId == null) return false;
    if (predefinedServiceIds.length > AppConstants.providerMaxServiceTypes) return false;
    try {
      await _client.from('profile_predefined_services').delete().eq('profile_id', profileId);
      if (predefinedServiceIds.isNotEmpty) {
        await _client.from('profile_predefined_services').insert(
          predefinedServiceIds.map((id) => {
            'profile_id': profileId,
            'predefined_service_id': id,
          }).toList(),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get predefined service ids for a profile.
  Future<List<String>> getProfilePredefinedServiceIds(String profileId) async {
    try {
      final res = await _client
          .from('profile_predefined_services')
          .select('predefined_service_id')
          .eq('profile_id', profileId);
      return (res as List).map((e) => e['predefined_service_id'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Publish profile (go live). Call after setup + preview.
  Future<bool> publishProfile(String profileId) async {
    if (_userId == null) return false;
    try {
      await _client.from('profiles').update({
        'is_live': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', profileId).eq('user_id', _userId!);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ProfileModel?> getProfile(String profileId) async {
    try {
      final res = await _client.from('profiles').select().eq('id', profileId).maybeSingle();
      return res != null ? ProfileModel.fromJson(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }
}
