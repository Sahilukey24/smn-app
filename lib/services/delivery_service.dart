import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/errors.dart';
import '../core/file_rules.dart';
import '../models/order_delivery_model.dart';
import '../models/order_model.dart';

/// File delivery: allowed mp4/mp3/pdf with size limits. Unlock only after "Ready for Delivery".
class DeliveryService {
  DeliveryService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _bucket = 'order-deliveries';

  String? get _userId => _client.auth.currentUser?.id;

  /// Check order is ready for delivery (creator clicked "Mark Ready for Delivery").
  Future<bool> canUploadForOrder(String orderId) async {
    final res = await _client.from('orders').select('ready_for_delivery_at, provider_id').eq('id', orderId).maybeSingle();
    if (res == null) return false;
    final ready = res['ready_for_delivery_at'] != null;
    final providerId = res['provider_id'] as String?;
    return ready && providerId == _userId;
  }

  /// Validate file: extension in (mp4, mp3, pdf) and under size limit.
  void validateFile(File file, String extension) {
    final ext = extension.toLowerCase().replaceFirst('.', '');
    if (!FileRules.isAllowedExtension(ext)) {
      throw InvalidFileTypeException();
    }
    final maxBytes = FileRules.maxBytesForExtension(ext);
    if (maxBytes == 0) throw ArgumentError('Invalid extension');
    final size = file.lengthSync();
    if (size > maxBytes) {
      final maxMb = ext == 'mp4' ? 200 : ext == 'mp3' ? 50 : 20;
      throw FileTooLargeException(maxMb);
    }
  }

  /// Upload delivery file. Call only after canUploadForOrder and validateFile.
  Future<OrderDeliveryModel?> uploadDelivery({
    required String orderId,
    required File file,
    required String fileType,
  }) async {
    if (_userId == null) return null;
    final can = await canUploadForOrder(orderId);
    if (!can) throw DeliveryNotReadyException();
    final ext = fileType.toLowerCase().replaceFirst('.', '');
    validateFile(file, ext);

    final path = '$orderId/${DateTime.now().millisecondsSinceEpoch}_${file.path.split(RegExp(r'[/\\]')).last}';
    await _client.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: FileOptions(upsert: true),
        );
    final size = file.lengthSync();

    final res = await _client.from('order_deliveries').insert({
      'order_id': orderId,
      'uploaded_by': _userId!,
      'file_path': path,
      'file_size_bytes': size,
      'file_type': ext,
    }).select().single();

    return OrderDeliveryModel.fromJson(res as Map<String, dynamic>);
  }

  Future<List<OrderDeliveryModel>> getDeliveriesForOrder(String orderId) async {
    final res = await _client.from('order_deliveries').select().eq('order_id', orderId).order('created_at', ascending: false);
    return (res as List).map((e) => OrderDeliveryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get signed download URL for a delivery (for buyer).
  Future<String?> getSignedDownloadUrl(String filePath, {int expiresIn = 3600}) async {
    try {
      final res = await _client.storage.from(_bucket).createSignedUrl(filePath, expiresIn);
      return res;
    } catch (_) {
      return null;
    }
  }
}
