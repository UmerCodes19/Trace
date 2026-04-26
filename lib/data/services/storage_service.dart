import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

class StorageService {
  final Dio _dio = Dio();
  
  // TODO: Replace with your Cloudinary credentials
  final String _cloudName = 'dntuudfhx';
  final String _uploadPreset = 'TraceApp';

  /// Upload an image to Cloudinary.
  /// Returns the secure URL.
  Future<String> _uploadToCloudinary(File file, String folder) async {
    try {
      final String url = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'upload_preset': _uploadPreset,
        'folder': folder,
      });

      final response = await _dio.post(url, data: formData);
      return response.data['secure_url'];
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      rethrow;
    }
  }

  /// Compress and upload a post image.
  Future<String> uploadPostImage(File file, String userId) async {
    return await _uploadToCloudinary(file, 'posts/$userId');
  }

  /// Upload user avatar.
  Future<String> uploadAvatar(File file, String userId) async {
    return await _uploadToCloudinary(file, 'avatars/$userId');
  }

  /// Upload a chat image.
  Future<String> uploadChatImage(File file, String chatId) async {
    return await _uploadToCloudinary(file, 'chats/$chatId');
  }

  Future<void> deleteFile(String url) async {
    // Cloudinary deletion usually requires admin API or signed requests
    // For client-side, we might just skip it or implement it if needed
    debugPrint('Cloudinary delete requested for: $url (not implemented)');
  }

  // Cloudinary handles compression and resizing on the fly
}
