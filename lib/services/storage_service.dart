import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Storage for post images and avatars.
class StorageService {
  SupabaseClient get _client => Supabase.instance.client;
  static const postImagesBucket = 'post-images';
  static const avatarsBucket = 'avatars';

  String _filePath(String bucket, String userId, String filename) {
    return '$userId/${DateTime.now().millisecondsSinceEpoch}_$filename';
  }

  Future<String?> uploadPostImage({
    required String userId,
    required File file,
  }) async {
    try {
      final path = _filePath(postImagesBucket, userId, file.path.split(RegExp(r'[/\\]')).last);
      await _client.storage.from(postImagesBucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from(postImagesBucket).getPublicUrl(path);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    try {
      final path = _filePath(avatarsBucket, userId, file.path.split(RegExp(r'[/\\]')).last);
      await _client.storage.from(avatarsBucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from(avatarsBucket).getPublicUrl(path);
    } catch (e) {
      rethrow;
    }
  }
}
