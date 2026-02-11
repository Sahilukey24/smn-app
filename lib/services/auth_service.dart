import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import 'profile_service.dart';

/// Handles Supabase auth, session persistence, and local role cache.
class AuthService {
  AuthService() : _profileService = ProfileService();

  static const _keyRole = 'smn_selected_role';

  final ProfileService _profileService;
  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  String? _cachedRole;
  String? get currentRole => _cachedRole;

  Future<String?> loadStoredRole() async {
    if (_cachedRole != null) return _cachedRole;
    final prefs = await SharedPreferences.getInstance();
    _cachedRole = prefs.getString(_keyRole);
    return _cachedRole;
  }

  Future<void> setRole(String role) async {
    if (currentUser == null) return;
    _cachedRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
    await _profileService.updateRole(currentUser!.id, role);
  }

  Future<void> clearRole() async {
    _cachedRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRole);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username ?? email.split('@').first},
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await clearRole();
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
