import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../utils/app_theme.dart';
import '../../services/connectivity_service.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_upload_service.dart';
import '../../services/app_session.dart';


/// GPS Camera Upload screen with:
/// - Loan selection dropdown (required before capture)
/// - Camera + gallery image capture
/// - Real-time GPS location tagging
/// - Offline-first: saves locally, auto-uploads when online
/// - Live connectivity status badge
/// - Pending + uploaded uploads queue
class GpsCameraUploadScreen extends StatefulWidget {
  const GpsCameraUploadScreen({super.key});

  @override
  State<GpsCameraUploadScreen> createState() => _GpsCameraUploadScreenState();
}

class _GpsCameraUploadScreenState extends State<GpsCameraUploadScreen> {
  // ─── Loan Data ─────────────────────────────────────────────────────────────
  List<Map<String, String>> _availableLoans = [];
  String? _selectedLoanId;
  bool _isLoadingLoans = true;
  Map<String, int> _uploadCounts = {};

  // ─── Capture State ─────────────────────────────────────────────────────────
  File? _image;
  Position? _position;
  DateTime? _timestamp;
  bool _isFetchingLocation = false;
  bool _isUploading = false;
  String? _errorMessage;

  // ─── Upload Queue ──────────────────────────────────────────────────────────
  List<PendingUpload> _allUploads = [];

  // ─── Services ──────────────────────────────────────────────────────────────
  final _picker = ImagePicker();
  final _storage = StorageService();
  final _firestoreUpload = FirestoreUploadService();
  final _connectivity = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _fetchLoansFromFirestore();
    _fetchUploadCounts();
    
    _loadUploads();
    // Listen for connectivity changes to update the UI in real-time
    _connectivity.addListener(_onConnectivityChanged);
    // Refresh uploads list when auto-sync completes in background
    _connectivity.onSyncComplete = _loadUploads;
  }

  Future<void> _fetchUploadCounts() async {
    final phone = AppSession.beneficiaryPhone;
    if (phone == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('uploads')
          .where('phone', isEqualTo: phone)
          .get();
          
      Map<String, int> counts = {};
      for (var doc in snap.docs) {
        final data = doc.data();
        final lId = data['loanId'] as String?;
        if (lId != null) {
          counts[lId] = (counts[lId] ?? 0) + 1;
        }
      }
      
      if (mounted) {
        setState(() {
          _uploadCounts = counts;
          _updateErrorMessage();
        });
      }
    } catch (e) {
      print('Error fetching upload counts: $e');
    }
  }

  void _updateErrorMessage() {
    if (_selectedLoanId == null) return;

    final selectedLoan = _availableLoans.firstWhere((l) => l['id'] == _selectedLoanId, orElse: () => {});
    if (selectedLoan['status'] == 'rejected') {
      _errorMessage = 'Your loan has been rejected. You cannot upload proof anymore. Please contact the bank.';
      return;
    }

    int onlineCount = _uploadCounts[_selectedLoanId!] ?? 0;
    int offlineCount = _allUploads.where((u) => u.loanId == _selectedLoanId && u.status == 'pending').length;
    int total = onlineCount + offlineCount;
    
    if (total >= 2) {
      _errorMessage = 'You have exceeded the maximum of 2 uploads for this loan. Please contact the bank.';
    } else if (_errorMessage == 'You have exceeded the maximum of 2 uploads for this loan. Please contact the bank.' ||
               _errorMessage == 'Your loan has been rejected. You cannot upload proof anymore. Please contact the bank.') {
      _errorMessage = null;
    }
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    _connectivity.onSyncComplete = null;
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUploads() async {
    final uploads = await _storage.getAllUploads(phone: AppSession.beneficiaryPhone);
    if (mounted) {
      setState(() {
        _allUploads = uploads;
        _updateErrorMessage();
      });
    }
  }
 
  Future<void> _fetchLoansFromFirestore() async {
    try {
      final phone = AppSession.beneficiaryPhone;
      if (phone == null || phone.isEmpty) {
        if (mounted) setState(() => _isLoadingLoans = false);
        return;
      }
      
      final snap = await FirebaseFirestore.instance.collection('beneficiaries').where('phone', isEqualTo: phone).get();
      
      if (mounted) {
        setState(() {
          _availableLoans = snap.docs.map((doc) {
            final data = doc.data();
            return {
              'id': data['loanId']?.toString() ?? 'N/A',
              'name': data['loanPurpose']?.toString() ?? 'Unknown Purpose',
              'status': data['status']?.toString() ?? 'pending',
            };
          }).toList();

          if (_availableLoans.isNotEmpty && (_selectedLoanId == null || !_availableLoans.any((l) => l['id'] == _selectedLoanId))) {
            _selectedLoanId = _availableLoans.first['id'];
          }
          _isLoadingLoans = false;
          _updateErrorMessage();
        });
      }
    } catch (e) {
      print('Error fetching loans: $e');
      if (mounted) setState(() => _isLoadingLoans = false);
    }
  }
  // ─── Location ────────────────────────────────────────────────────────────────

  Future<Position?> _fetchLocation() async {
    setState(() { _isFetchingLocation = true; _errorMessage = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return null;
      if (!serviceEnabled) {
        setState(() => _errorMessage = 'Location services are disabled. Please enable GPS.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return null;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return null;
        if (permission == LocationPermission.denied) {
          setState(() => _errorMessage = 'Location permission denied.');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage = 'Location permission permanently denied. Please enable it in Settings.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Could not fetch location: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // ─── Camera & Gallery ─────────────────────────────────────────────────────────

  Future<void> _capturePhoto() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickImage(ImageSource source) async {
    print('📷 User initiated image capture/picking from $source');
    
    if (!mounted) return;
    if (_selectedLoanId == null) {
      setState(() => _errorMessage = 'Please select a loan before capturing.');
      return;
    }

    final position = await _fetchLocation();

    try {
      print('📸 Opening native image picker...');
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 60, // Limit quality to save memory
        maxWidth: 1024,   // Critical: Limit dimensions to prevent "Lost connection to device" Out Of Memory when returning from camera
        maxHeight: 1024,
      );
      
      print('📸 Image picker returned. Validating response...');
      
      if (!mounted) {
        print('⚠️ Widget no longer mounted after camera returned.');
        return;
      }
      
      if (picked == null) {
        print('⚠️ Image picking cancelled by user.');
        return;
      }

      print('✅ Image captured successfully at: ${picked.path}');

      setState(() {
        _image = File(picked.path);
        _position = position;
        _timestamp = DateTime.now();
        _errorMessage = null;
      });
      print('✅ Widget state updated with new image.');
    } catch (e, st) {
      print('❌ Error picking image: $e');
      print('❌ Stack trace: $st');
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not pick image: $e');
    }
  }

  // ─── Save & Upload Logic ──────────────────────────────────────────────────────

  Future<String> _saveImageLocally(File tempImage) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_proof.jpg';
    final savedImage = await tempImage.copy(path.join(directory.path, fileName));
    return savedImage.path;
  }

  /// Saves the current capture to SQLite as 'pending' (offline-only path).
  /// The local file path is stored temporarily; [ConnectivityService] auto-sync
  /// will call [UploadService.uploadProof] → Cloudinary → Firestore and then
  /// replace the local path with the Cloudinary URL via [markAsUploadedWithUrl].
  ///
  /// NEVER stores local file path to Firestore — only the Cloudinary URL ever
  /// reaches Firestore, handled by [UploadService] during sync.
  Future<void> _saveOfflineRecord() async {
    if (_image == null || _selectedLoanId == null) return;

    try {
      print('📴 Saving offline record to SQLite...');
      final loanName = _availableLoans.firstWhere((l) => l['id'] == _selectedLoanId, orElse: () => {'id': _selectedLoanId!, 'name': 'Unknown Loan'})['name'] ?? 'Unknown Loan';
      final localImagePath = await _saveImageLocally(_image!);

      final uploadRecord = PendingUpload(
        imagePath: localImagePath,  // ← local path stored ONLY in SQLite (never sent to Firestore)
        localPath: localImagePath,  // ← fallback for offline thumbnail display
        loanId: _selectedLoanId!,
        loanName: loanName,
        latitude: _position?.latitude ?? 0.0,
        longitude: _position?.longitude ?? 0.0,
        timestamp: _timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
        phone: AppSession.beneficiaryPhone,
        status: 'pending',
      );

      final insertedId = await _storage.insertUpload(uploadRecord);
      print('✅ Offline record saved to SQLite, id=$insertedId (status: pending)');
      print('ℹ️  ConnectivityService will upload when internet returns → Cloudinary URL → Firestore');

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved offline. Will auto-upload when internet returns.'),
          backgroundColor: AppTheme.blue600,
        ),
      );

      // Reset capture state and reload queue
      setState(() {
        _image = null;
        _position = null;
        _timestamp = null;
        // Keep _selectedLoanId selected to speed up next captures
      });
      await _loadUploads();

    } catch (e, st) {
      print('❌ Offline save failed: $e');
      print('❌ Stack trace: $st');
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not save offline: $e');
    }
  }

  /// Called after a successful Cloudinary + Firestore upload.
  /// Saves a local copy marked as 'uploaded' (storing the Cloudinary URL)
  /// and navigates to success screen.
  Future<void> _processUploadWithUrl(String imageUrl) async {
    print('🛠️ Step 4: Storing uploaded record locally...');
    
    if (_image == null || _selectedLoanId == null) {
      print('❌ Verification failed: Image or Loan ID is null');
      return;
    }
    
    try {
      final loanName = _availableLoans.firstWhere((l) => l['id'] == _selectedLoanId, orElse: () => {'id': _selectedLoanId!, 'name': 'Unknown Loan'})['name'] ?? 'Unknown Loan';
      final localImagePath = await _saveImageLocally(_image!);

      // Store the Cloudinary URL in imagePath so the local queue can display it
      final uploadRecord = PendingUpload(
        imagePath: imageUrl,          // ← Cloudinary URL, NOT local file path
        localPath: localImagePath,    // ← kept for offline fallback preview
        loanId: _selectedLoanId!,
        loanName: loanName,
        latitude: _position?.latitude ?? 0.0,
        longitude: _position?.longitude ?? 0.0,
        timestamp: _timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
        phone: AppSession.beneficiaryPhone,
        status: 'uploaded',
      );
      
      print('🛠️ Step 5: Marking record as uploaded in local SQLite DB...');
      final insertedId = await _storage.insertUpload(uploadRecord);
      await _storage.markAsUploaded(insertedId);

      print('🛠️ Step 6: Handling UI completion and navigating to success screen...');
      if (!mounted) {
        print('⚠️ Widget not mounted, aborting navigation.');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully!'), backgroundColor: AppTheme.green600, duration: Duration(seconds: 2)),
      );
      
      // Ensure navigation is safe
      Navigator.pushReplacementNamed(context, '/submission-success');
      print('✅ Navigation to /submission-success initiated.');
    } catch (e, st) {
      print('❌ Local save or processing failed: $e');
      print('❌ Stack trace: $st');
      if (!mounted) return;
      setState(() => _errorMessage = 'Local processing failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification during local save failed: $e'), backgroundColor: AppTheme.red600),
      );
    }
  }

  // ─── Formatters ──────────────────────────────────────────────────────────────

  String get _formattedTimestamp =>
      _timestamp != null ? DateFormat('dd MMM yyyy, hh:mm a').format(_timestamp!) : '';

  String get _formattedLocation => _position != null
      ? 'Lat: ${_position!.latitude.toStringAsFixed(4)}, Lng: ${_position!.longitude.toStringAsFixed(4)}'
      : 'Location unavailable';

  String _formatIsoDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM, hh:mm a').format(date);
    } catch (_) {
      return '';
    }
  }

  // Helpers
  List<PendingUpload> get _pendingUploads => _allUploads.where((u) => u.status == 'pending').toList();
  List<PendingUpload> get _uploadedUploads => _allUploads.where((u) => u.status == 'uploaded').toList();

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  label: const Text('Back', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                const SizedBox(height: 16),
                const Text('GPS Camera Upload',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Capture proof of loan utilization',
                        style: TextStyle(color: Colors.blue[100], fontSize: 13)),
                    // Real-time connectivity badge
                    _buildConnectivityBadge(),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        border: Border.all(color: const Color(0xFFFECACA)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.red600, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: const TextStyle(fontSize: 12, color: AppTheme.red600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Syncing indicator
                  if (_connectivity.isSyncing) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Syncing pending uploads…',
                              style: TextStyle(fontSize: 12, color: AppTheme.blue600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // ── Step 1: Loan Selection Dropdown ──────────────────────────
                  const Text('1. Select Loan', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.gray800)),
                  const SizedBox(height: 8),
                  if (_isLoadingLoans)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator()))
                  else if (_availableLoans.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                      child: const Text('No loans available to snap proof.', style: TextStyle(color: AppTheme.red600)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _selectedLoanId != null ? AppTheme.green600 : AppTheme.gray300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLoanId,
                          hint: const Text('Select a loan...'),
                          isExpanded: true,
                          items: _availableLoans.map((loan) {
                            return DropdownMenuItem<String>(
                              value: loan['id'],
                              child: Text('${loan['name']} (${loan['id']})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedLoanId = val;
                              _errorMessage = null;
                              _updateErrorMessage();
                            });
                          },
                        ),
                      ),
                    ),

                  // Show selected loan info
                  if (!_isLoadingLoans && _selectedLoanId != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.green600, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Selected: ${_availableLoans.firstWhere((l) => l['id'] == _selectedLoanId)['name']}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.green600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Step 2: Image Preview ────────────────────────────────────
                  const Text('2. Capture Proof', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.gray800)),
                  const SizedBox(height: 8),
                  _buildImagePreview(),
                  const SizedBox(height: 16),

                  // Capture button
                  SizedBox(
                    width: double.infinity,
                    child: _buildCaptureButton(),
                  ),
                  const SizedBox(height: 16),

                  // Upload/Save button
                  if (_image != null) _buildUploadButton(),

                  const SizedBox(height: 32),

                  // ── Pending Uploads Queue ────────────────────────────────────
                  if (_pendingUploads.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pending Uploads',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gray800)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(20)),
                          child: Text('${_pendingUploads.length} item(s)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildUploadsList(_pendingUploads, isPending: true),
                    const SizedBox(height: 24),
                  ],

                  // ── Uploaded Items ────────────────────────────────────────────
                  if (_uploadedUploads.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Successfully Uploaded',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.gray800)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)),
                          child: Text('${_uploadedUploads.length} item(s)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800])),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildUploadsList(_uploadedUploads, isPending: false),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widgets ─────────────────────────────────────────────────────────────────

  /// Real-time connectivity badge (green = online, orange = offline)
  Widget _buildConnectivityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _connectivity.isOnline ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _connectivity.isOnline ? 'ONLINE' : 'OFFLINE',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_image == null) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.gray300, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFDBEAFE), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, size: 40, color: AppTheme.blue600),
            ),
            const SizedBox(height: 16),
            const Text('No photo captured',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.gray600)),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Full-width image
          Image.file(
            _image!,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // GPS overlay at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xCC000000),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF60A5FA), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formattedLocation,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF86EFAC), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formattedTimestamp,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Accuracy badge (top-right)
          if (_position != null)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xCC000000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_fixed, color: Color(0xFF4ADE80), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '±${_position!.accuracy.toStringAsFixed(0)}m',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    final bool isLoading = _isFetchingLocation;
    int onlineCount = _selectedLoanId != null ? (_uploadCounts[_selectedLoanId!] ?? 0) : 0;
    int offlineCount = _selectedLoanId != null ? _allUploads.where((u) => u.loanId == _selectedLoanId && u.status == 'pending').length : 0;
    bool isMaxedOut = (onlineCount + offlineCount) >= 2;
    
    final selectedLoan = _selectedLoanId != null 
        ? _availableLoans.firstWhere((l) => l['id'] == _selectedLoanId, orElse: () => {})
        : {};
    bool isRejected = selectedLoan['status'] == 'rejected';

    bool isDisabled = isLoading || isMaxedOut || isRejected;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isDisabled ? AppTheme.gray300 : AppTheme.blue600),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : _capturePhoto,
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.camera_alt, color: AppTheme.blue600, size: 20),
        label: Text(
          isLoading ? 'GPS…' : 'Camera',
          style: const TextStyle(color: AppTheme.blue600, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    final isOnline = _connectivity.isOnline;
    int onlineCount = _selectedLoanId != null ? (_uploadCounts[_selectedLoanId!] ?? 0) : 0;
    int offlineCount = _selectedLoanId != null ? _allUploads.where((u) => u.loanId == _selectedLoanId && u.status == 'pending').length : 0;
    bool isMaxedOut = (onlineCount + offlineCount) >= 2;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [const Color(0xFF059669), const Color(0xFF10B981)]
              : [const Color(0xFFD97706), const Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? const Color(0xFF059669) : const Color(0xFFD97706)).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: (_isUploading || isMaxedOut)
            ? null
            : () async {
                print('📸 UPLOAD BUTTON CLICKED');

                // ── Null-safety guards ────────────────────────────────────────
                if (_image == null) {
                  setState(() => _errorMessage = 'Please capture a photo first.');
                  return;
                }
                if (_selectedLoanId == null) {
                  setState(() => _errorMessage = 'Please select a loan first.');
                  return;
                }

                setState(() { _isUploading = true; _errorMessage = null; });

                try {
                  print('🛠️ Step 1: Initiating upload procedure...');
                  
                  // Ensure identity data is present
                  final phone = AppSession.beneficiaryPhone;
                  if (phone == null || phone.isEmpty) {
                     throw Exception('Missing User Identity. Please log out and back in.');
                  }

                  if (isOnline) {
                    print('🌐 ONLINE: Processing Cloudinary → Firestore pipeline...');
                    print('📍 Validating data: Phone: $phone, LoanID: $_selectedLoanId');

                    // Single pipeline: upload file → secure_url → Firestore (no file.path)
                    print('🛠️ Step 2: Uploading image to Cloudinary and creating Firestore document...');
                    final String? imageUrl = await _firestoreUpload.uploadLoanProof(
                      imageFile: _image!,
                      loanId: _selectedLoanId!,
                      latitude: _position?.latitude ?? 0.0,
                      longitude: _position?.longitude ?? 0.0,
                      timestamp: _timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
                      phone: phone,
                    );

                    print('🛠️ Step 3: Validating URL response...');
                    if (imageUrl == null || imageUrl.trim().isEmpty) {
                      throw Exception('Upload failed: Server validation error (secure_url is null/empty).');
                    }

                    print('✅ Remote secure URL retrieved: $imageUrl');

                    await _processUploadWithUrl(imageUrl);
                    print('🎉 COMPLETE: Online upload flow finished securely');
                  } else {
                    // ── Offline path: save to SQLite only, auto-sync will handle upload ──
                    print('📴 OFFLINE: User disconnected. Fallback to SQLite local queue...');
                    await _saveOfflineRecord();
                    print('✅ Offline fallback completed');
                  }
                } catch (e, st) {
                  print('❌ Upload flow RUNTIME ERROR: $e');
                  print('❌ Stack trace: $st');
                  if (!mounted) {
                     print('⚠️ Widget disposed before error could be shown.');
                     return;
                  }
                  setState(() => _errorMessage = 'Upload failed: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.red600, duration: const Duration(seconds: 4)),
                  );
                } finally {
                  if (mounted) setState(() => _isUploading = false);
                  print('🏁 END: Upload transaction finalized.');
                }
              },
        icon: _isUploading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(isOnline ? Icons.cloud_upload : Icons.save_alt, color: Colors.white),
        label: Text(
          _isUploading ? 'Processing…' : (isOnline ? 'Upload Now' : 'Save Offline'),
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  /// Builds a list of upload items (pending or completed)
  Widget _buildUploadsList(List<PendingUpload> uploads, {required bool isPending}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: uploads.length,
      itemBuilder: (context, index) {
        final upload = uploads[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isPending ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // ── Show network image for uploaded items (Cloudinary URL),
              //    local file image for pending items not yet synced.
              child: upload.status == 'uploaded' &&
                      upload.imagePath.startsWith('http')
                  ? Image.network(
                      upload.imagePath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) => p == null
                          ? child
                          : Container(
                              width: 60, height: 60,
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                          width: 60, height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey)),
                    )
                  : Image.file(
                      File(upload.localPath ?? upload.imagePath),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 60, height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey)),
                    ),
            ),
            title: Text(upload.loanName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.gray800)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Loan: ${upload.loanId}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.gray500),
                ),
                const SizedBox(height: 2),
                Text(_formatIsoDate(upload.timestamp), style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                const SizedBox(height: 4),
                // Status badge
                Row(
                  children: [
                    Icon(
                      isPending ? Icons.schedule : Icons.check_circle,
                      size: 12,
                      color: isPending ? Colors.orange : AppTheme.green600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPending ? 'Pending sync…' : 'Uploaded',
                      style: TextStyle(
                        fontSize: 11,
                        color: isPending ? Colors.orange[800] : AppTheme.green600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: isPending
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.red600),
                    onPressed: () async {
                      await _storage.deleteUpload(upload.id!);
                      _loadUploads();
                    },
                  )
                : const Icon(Icons.check_circle, color: AppTheme.green600, size: 20),
          ),
        );
      },
    );
  }
}
