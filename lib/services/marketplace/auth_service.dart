import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../models/role_model.dart';

/// Auth + user/role for marketplace. OTP via MSG91 to be wired separately.
class MarketplaceAuthService {
  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get currentUserId => currentUser?.id;

  /// Ensure public.users row exists for current auth user.
  Future<UserModel?> ensureUser() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      await _client.from('users').upsert({
        'id': uid,
        'email': currentUser?.email,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      final res = await _client.from('users').select().eq('id', uid).maybeSingle();
      return res != null ? UserModel.fromJson(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: username != null ? {'username': username} : null,
    );
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Roles the user has paid for.
  Future<List<RoleModel>> getMyRoles() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final res = await _client.from('roles').select().eq('user_id', uid);
      return (res as List).map((e) => RoleModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Whether user has paid for this role.
  Future<bool> hasRolePaid(String role) async {
    final roles = await getMyRoles();
    return roles.any((r) => r.role == role && r.isPaid);
  }

  /// Mark role as paid (after Razorpay webhook or client success).
  Future<void> setRolePaid(String role) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('roles').upsert({
      'user_id': uid,
      'role': role,
      'paid_at': DateTime.now().toIso8601String(),
      'verified_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,role');
  }
}
