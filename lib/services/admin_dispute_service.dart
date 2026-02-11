import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/dispute_model.dart';
import '../models/manual_post_model.dart';

/// Admin: approve manual analytics, resolve disputes, release payouts, ban users.
/// Caller must ensure current user is admin (is_admin = true).
class AdminDisputeService {
  AdminDisputeService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<bool> _isAdmin() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final res = await _client.from('users').select('is_admin').eq('id', uid).maybeSingle();
    return (res as Map<String, dynamic>?)?['is_admin'] as bool? ?? false;
  }

  // ─── Manual analytics ────────────────────────────────────────────────────
  Future<bool> approveManualPost(String manualPostId) async {
    if (!await _isAdmin()) return false;
    try {
      await _client.from('manual_posts').update({
        'status': 'approved',
        'reviewed_by': _client.auth.currentUser?.id,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', manualPostId);
      await _logAdminAction('approve_manual_post', 'manual_post', manualPostId, null);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectManualPost(String manualPostId, [String? notes]) async {
    if (!await _isAdmin()) return false;
    try {
      await _client.from('manual_posts').update({
        'status': 'rejected',
        'reviewed_by': _client.auth.currentUser?.id,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', manualPostId);
      await _logAdminAction('reject_manual_post', 'manual_post', manualPostId, notes);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Disputes ─────────────────────────────────────────────────────────────
  Future<List<DisputeModel>> getOpenDisputes() async {
    if (!await _isAdmin()) return [];
    try {
      final res = await _client.from('disputes').select().eq('status', AppConstants.disputeOpen).order('created_at', ascending: false);
      return (res as List).map((e) => DisputeModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> resolveDispute(String disputeId, String resolutionNotes) async {
    if (!await _isAdmin()) return false;
    try {
      await _client.from('disputes').update({
        'status': AppConstants.disputeResolved,
        'admin_notes': resolutionNotes,
        'resolved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', disputeId);
      final row = await _client.from('disputes').select('order_id').eq('id', disputeId).single();
      final orderId = row['order_id'] as String;
      await _client.from('orders').update({
        'status': AppConstants.orderInProgress,
        'payout_frozen': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      await _logAdminAction('resolve_dispute', 'dispute', disputeId, resolutionNotes);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> closeDispute(String disputeId, String notes) async {
    if (!await _isAdmin()) return false;
    try {
      await _client.from('disputes').update({
        'status': AppConstants.disputeClosed,
        'admin_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', disputeId);
      await _logAdminAction('close_dispute', 'dispute', disputeId, notes);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Payouts ─────────────────────────────────────────────────────────────
  Future<bool> releasePayout(String orderId) async {
    if (!await _isAdmin()) return false;
    try {
      await _client.from('orders').update({
        'payout_frozen': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
      await _logAdminAction('release_payout', 'order', orderId, null);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Ban user ─────────────────────────────────────────────────────────────
  Future<bool> setUserBanned(String userId, bool banned) async {
    if (!await _isAdmin()) return false;
    try {
      await _client.from('users').update({
        'updated_at': DateTime.now().toIso8601String(),
        'banned': banned,
      }).eq('id', userId);
      await _logAdminAction(banned ? 'ban_user' : 'unban_user', 'user', userId, null);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _logAdminAction(String actionType, String referenceType, String referenceId, String? notes) async {
    final adminId = _client.auth.currentUser?.id;
    if (adminId == null) return;
    try {
      await _client.from('admin_actions').insert({
        'admin_id': adminId,
        'action_type': actionType,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'notes': notes,
      });
    } catch (_) {}
  }
}
