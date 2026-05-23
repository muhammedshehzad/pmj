import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

/// Single implementation of Cloudinary image upload.
/// Replaces four identical copy-pasted versions across the codebase.
class ImageUploadService {
  ImageUploadService._();
  static final ImageUploadService instance = ImageUploadService._();

  /// Uploads [file] to Cloudinary and returns the secure URL.
  /// Throws [ImageUploadException] on failure so callers can handle it cleanly.
  Future<String> upload(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.cloudinaryUploadUrl),
      )
        ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final url = data['secure_url'] as String?;
        if (url == null || url.isEmpty) {
          throw ImageUploadException('Upload succeeded but no URL returned.');
        }
        return url;
      } else {
        throw ImageUploadException(
          'Upload failed with status ${streamed.statusCode}.',
        );
      }
    } on ImageUploadException {
      rethrow;
    } catch (e, st) {
      debugPrint('ImageUploadService.upload error: $e\n$st');
      throw ImageUploadException('Could not upload image. Check your connection and try again.');
    }
  }
}

class ImageUploadException implements Exception {
  final String message;
  const ImageUploadException(this.message);

  @override
  String toString() => message;
}
