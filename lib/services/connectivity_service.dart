import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'storage_service.dart';
import 'upload_service.dart';

/// Singleton service that monitors network connectivity and
/// automatically uploads pending records when internet returns.
///
/// Uses [UploadService]: Cloudinary upload → Firestore `imageUrl` (not local paths).
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  /// Optional callback invoked after auto-sync completes
  VoidCallback? onSyncComplete;

  void initialize() {
    _checkInitialStatus();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialStatus() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final previouslyOnline = _isOnline;
    _isOnline = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    notifyListeners();
    if (_isOnline && !previouslyOnline) {
      _triggerAutoUpload();
    }
  }

  /// Auto-upload pending local files via Cloudinary + Firestore.
  Future<void> _triggerAutoUpload() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final storage = StorageService();
      final uploader = UploadService();
      final pendingUploads = await storage.getPendingUploads();
      if (pendingUploads.isEmpty) return;

      for (final upload in pendingUploads) {
        // For pending records, imagePath is always the local file path
        final imageFile = File(upload.localPath ?? upload.imagePath);
        if (await imageFile.exists()) {
          final imageUrl = await uploader.uploadProof(
            imageFile: imageFile,
            loanId: upload.loanId,
            latitude: upload.latitude,
            longitude: upload.longitude,
            timestamp: upload.timestamp,
            phone: upload.phone, // Pass the phone number so Officer Dashboard can filter it
          );
          if (imageUrl != null) {
            // ✅ Save the Cloudinary URL — not just flip the status
            await storage.markAsUploadedWithUrl(upload.id!, imageUrl);
            debugPrint('✅ Auto-synced record ${upload.id} → $imageUrl');
          } else {
            debugPrint('❌ Auto-sync failed for record ${upload.id}');
          }
        } else {
          // File missing — remove stale record to avoid infinite retry
          await storage.deleteUpload(upload.id!);
          debugPrint('🗑️  Deleted stale record ${upload.id} (file missing)');
        }
      }

      onSyncComplete?.call();
    } catch (e) {
      debugPrint('Auto-upload error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Manually trigger a sync (e.g., from a "Retry All" button)
  Future<void> manualSync() async {
    if (!_isOnline || _isSyncing) return;
    await _triggerAutoUpload();
  }
}
