import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

/// Uploads images to Cloudinary using an UNSIGNED upload preset.
/// NO api_key, NO api_secret — safe for Flutter mobile apps.
///
/// Set in `.env` (optional): `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UPLOAD_PRESET`
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  static const String _defaultCloudName = 'dm8h6avf7';
  static const String _defaultUploadPreset = 'loan_upload';

  String get _cloudName {
    try {
      if (!dotenv.isInitialized) return _defaultCloudName;
      final e = dotenv.env['CLOUDINARY_CLOUD_NAME']?.trim();
      return (e != null && e.isNotEmpty) ? e : _defaultCloudName;
    } catch (_) {
      return _defaultCloudName;
    }
  }

  String get _uploadPreset {
    try {
      if (!dotenv.isInitialized) return _defaultUploadPreset;
      final e = dotenv.env['CLOUDINARY_UPLOAD_PRESET']?.trim();
      return (e != null && e.isNotEmpty) ? e : _defaultUploadPreset;
    } catch (_) {
      return _defaultUploadPreset;
    }
  }

  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload [file] to Cloudinary.
  /// Returns the secure_url on success.
  /// Throws [CloudinaryUploadException] on failure — never returns null.
  Future<String> uploadToCloudinary(File file) async {
    // ── Guard: file must exist ────────────────────────────────────────
    if (!await file.exists()) {
      throw CloudinaryUploadException(
          'Image file not found at path: ${file.path}');
    }

    print('UPLOADING IMAGE → $_uploadUrl (preset: $_uploadPreset)');

    // ── Build multipart request ───────────────────────────────────────
    // ONLY send upload_preset + file. Any extra field (api_key, etc.)
    // on an unsigned preset causes Cloudinary to return 401.
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    // ── Send ─────────────────────────────────────────────────────────
    final streamed = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw CloudinaryUploadException('Upload timed out (60s)'),
    );
    final response = await http.Response.fromStream(streamed);

    print('Cloudinary status: ${response.statusCode}');
    print('Cloudinary body: ${response.body}');

    // ── Parse ────────────────────────────────────────────────────────
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw CloudinaryUploadException('No secure_url in Cloudinary response');
      }

      print('IMAGE UPLOADED: $secureUrl');
      return secureUrl;
    } else {
      print('ERROR: ${response.statusCode} → ${response.body}');
      String detailedError = response.body;
      try {
        final parsedJson = jsonDecode(response.body);
        if (parsedJson['error'] != null && parsedJson['error']['message'] != null) {
          detailedError = parsedJson['error']['message'];
        }
      } catch (_) {
        // Fallback to raw body if JSON parsing fails
      }
      throw CloudinaryUploadException(detailedError);
    }
  }
}

/// Thrown when a Cloudinary upload fails.
class CloudinaryUploadException implements Exception {
  final String message;
  const CloudinaryUploadException(this.message);

  @override
  String toString() => message;
}
