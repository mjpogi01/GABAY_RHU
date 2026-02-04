import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/cloudinary_config.dart';

/// Uploads module images to Cloudinary (unsigned preset). Returns the public URL or null on failure.
class CloudinaryUploadService {
  static const String _uploadUrlTemplate =
      'https://api.cloudinary.com/v1_1/{cloud}/image/upload';

  /// Uploads image bytes and returns the secure URL, or null if not configured or upload fails.
  static Future<String?> uploadImage({
    required List<int> bytes,
    required String publicId,
    String? folder,
  }) async {
    if (!CloudinaryConfig.isConfigured) return null;

    final url = _uploadUrlTemplate.replaceFirst(
      '{cloud}',
      CloudinaryConfig.cloudName,
    );

    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['public_id'] = publicId;
    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    final ext = publicId.contains('.') ? '' : '.jpg';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: publicId + ext,
      ),
    );

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    } catch (_) {
      return null;
    }
  }
}
