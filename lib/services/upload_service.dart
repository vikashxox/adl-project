import 'dart:io';
import 'firestore_upload_service.dart';

/// Offline sync entry: same pipeline as [FirestoreUploadService.uploadLoanProof].
/// Cloudinary → Firestore `imageUrl` only (never local [File.path]).
class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final _firestoreUpload = FirestoreUploadService();

  /// Returns Cloudinary **secure_url** on success, or **null**.
  Future<String?> uploadProof({
    required File imageFile,
    required String loanId,
    required double latitude,
    required double longitude,
    required String timestamp,
    String? phone,
  }) {
    return _firestoreUpload.uploadLoanProof(
      imageFile: imageFile,
      loanId: loanId,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      phone: phone,
    );
  }
}
