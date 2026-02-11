import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// Fraud detection: perceptual hash, ffmpeg frame sampling, audio fingerprint.
/// 90% similarity = unchanged. Actual hashing/fingerprinting runs on backend or native; this is the interface + stub.
class FraudDetector {
  FraudDetector([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const double unchangedThreshold = AppConstants.fraudUnchangedSimilarityThreshold;

  /// Result of comparing new delivery to previous (e.g. revision).
  Future<FraudCheckResult> checkUnchanged({
    required String orderId,
    required String deliveryId,
    required File newFile,
    required String fileType,
    String? previousDeliveryPath,
  }) async {
    // Stub: real implementation would:
    // - perceptual hash for images/PDF
    // - ffmpeg frame sampling for video (mp4)
    // - audio fingerprint for audio (mp3)
    // - compare with previous delivery; if similarity >= 90% → unchanged
    final similarity = await _computeSimilarityStub(newFile, fileType, previousDeliveryPath);
    final isUnchanged = similarity >= unchangedThreshold;

    try {
      await _client.from('fraud_checks').insert({
        'order_id': orderId,
        'delivery_id': deliveryId,
        'check_type': fileType == 'mp4' ? 'frame_sample' : (fileType == 'mp3' ? 'audio_fingerprint' : 'perceptual_hash'),
        'similarity_percent': similarity,
        'is_unchanged': isUnchanged,
        'details_json': {'stub': true},
      });
    } catch (_) {}

    return FraudCheckResult(
      similarityPercent: similarity,
      isUnchanged: isUnchanged,
    );
  }

  Future<double> _computeSimilarityStub(File file, String fileType, String? previousPath) async {
    // Stub: return 0 (changed) so revisions are not auto-flagged. Replace with real backend call.
    await Future.delayed(const Duration(milliseconds: 100));
    return 0.0;
  }

  /// Fetch last fraud check for a delivery (e.g. to apply refund/payout rules).
  Future<FraudCheckResult?> getLastCheckForDelivery(String deliveryId) async {
    try {
      final res = await _client.from('fraud_checks').select().eq('delivery_id', deliveryId).order('created_at', ascending: false).limit(1).maybeSingle();
      if (res == null) return null;
      return FraudCheckResult(
        similarityPercent: (res['similarity_percent'] as num).toDouble(),
        isUnchanged: res['is_unchanged'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}

class FraudCheckResult {
  const FraudCheckResult({
    required this.similarityPercent,
    required this.isUnchanged,
  });
  final double similarityPercent;
  final bool isUnchanged;
}
