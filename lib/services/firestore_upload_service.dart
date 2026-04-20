import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_service.dart';

/// Service for uploading loan proof: image → Cloudinary, then metadata → Firestore.
///
/// Flow: **Capture → uploadToCloudinary(File) → secure_url → Firestore `imageUrl` only.**
/// Never persists [File.path] or any local path to Firestore.
class FirestoreUploadService {
  static final FirestoreUploadService _instance = FirestoreUploadService._internal();
  factory FirestoreUploadService() => _instance;
  FirestoreUploadService._internal();

  final _cloudinary = CloudinaryService();

  /// Upload [imageFile] to Cloudinary, then save the full record to Firestore.
  ///
  /// Returns the Cloudinary **secure_url** on success, or **null** if upload or save fails.
  /// Does **not** write to Firestore unless Cloudinary returns a valid `http(s)` URL.
  Future<String?> uploadLoanProof({
    required File imageFile,
    required String loanId,
    required double latitude,
    required double longitude,
    required String timestamp,
    String? phone,
  }) async {
    try {
      print('🚀 FirestoreUploadService.uploadLoanProof: start');

      if (!await imageFile.exists()) {
        print('❌ imageFile does not exist — abort');
        return null;
      }

      // ── Step 1: Cloudinary → secure_url ─────────────────────────────────
      print('☁️  Uploading to Cloudinary...');
      final imageUrl = await _cloudinary.uploadToCloudinary(imageFile);
      print('✅ Cloudinary secure_url = $imageUrl');

      if (!_isValidRemoteImageUrl(imageUrl)) {
        print('❌ Invalid imageUrl after upload — NOT saving to Firestore');
        return null;
      }

      // ── Step 2: Firestore — ONLY imageUrl (never imagePath / file.path) ──
      await FirebaseFirestore.instance.collection('uploads').add(_uploadPayload(
            imageUrl: imageUrl,
            loanId: loanId,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            phone: phone ?? 'anonymous',
          ));

      print('✅ Firestore document added with imageUrl only');
      return imageUrl;
    } catch (e, st) {
      print('❌ uploadLoanProof failed: $e');
      print('$st');
      rethrow;
    }
  }

  static bool _isValidRemoteImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final u = url.trim();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  /// Payload for `uploads` collection — **must not** include local paths.
  Map<String, dynamic> _uploadPayload({
    required String imageUrl,
    required String loanId,
    required double latitude,
    required double longitude,
    required String timestamp,
    required String phone,
  }) {
    return {
      'imageUrl': imageUrl,
      'loanId': loanId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'phone': phone,
      'role': 'beneficiary',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Save upload metadata to Firestore using a pre-uploaded Cloudinary URL.
  /// Use this when you already have the imageUrl from a previous upload.
  Future<bool> saveUploadRecord({
    required String imageUrl,
    required String loanId,
    required double latitude,
    required double longitude,
    required String timestamp,
    String? phone,
  }) async {
    try {
      if (!_isValidRemoteImageUrl(imageUrl)) {
        print('❌ saveUploadRecord: invalid imageUrl — not saving');
        return false;
      }

      await FirebaseFirestore.instance.collection('uploads').add(_uploadPayload(
            imageUrl: imageUrl.trim(),
            loanId: loanId,
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            phone: phone ?? 'anonymous',
          ));

      print('✅ Upload record saved to Firestore (imageUrl only)');
      return true;
    } catch (e) {
      print('❌ Failed to save upload record: $e');
      return false;
    }
  }
}