import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/cloudinary_service.dart';     // ✅ canonical (duplicate deleted)
import '../services/firestore_upload_service.dart';

/// Example usage of the upload services in a Flutter widget.
/// This shows the correct flow: Capture → Upload → Save URL → Display
class UploadExample extends StatefulWidget {
  const UploadExample({super.key});

  @override
  State<UploadExample> createState() => _UploadExampleState();
}

class _UploadExampleState extends State<UploadExample> {
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  final _firestoreUpload = FirestoreUploadService();

  File? _image;
  Position? _position;
  bool _isUploading = false;
  String? _errorMessage;
  String? _uploadedImageUrl;

  // ─── Capture Image ──────────────────────────────────────────────────────
  Future<void> _captureImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (picked != null) {
        if (!mounted) return;
        setState(() {
          _image = File(picked.path);
          _errorMessage = null;
        });

        // Get GPS location
        await _getLocation();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to capture image: $e');
    }
  }

  // ─── Get GPS Location ───────────────────────────────────────────────────
  Future<void> _getLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _position = position);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to get location: $e');
    }
  }

  // ─── Upload Flow: Cloudinary → Firestore ───────────────────────────────
  Future<void> _uploadImage() async {
    if (_image == null) {
      setState(() => _errorMessage = 'Please capture an image first');
      return;
    }

    if (_position == null) {
      setState(() => _errorMessage = 'GPS location required');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      print('🚀 Starting upload process...');

      // ── Step 1: Upload to Cloudinary ────────────────────────────────────
      print('☁️  Uploading to Cloudinary...');
      final imageUrl = await _cloudinary.uploadToCloudinary(_image!);
      print('✅ Got Cloudinary URL: $imageUrl');

      // ── Step 2: Save to Firestore (ONLY the URL) ───────────────────────
      final success = await _firestoreUpload.saveUploadRecord(
        imageUrl: imageUrl,
        loanId: 'L-1001', // Example loan ID
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        timestamp: DateTime.now().toIso8601String(),
        userId: 'user123',
      );

      if (success) {
        if (!mounted) return;
        setState(() => _uploadedImageUrl = imageUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Upload successful!'),
            backgroundColor: Colors.green,
          ),
        );

        print('🎉 Upload complete! Image URL: $imageUrl');
      } else {
        if (!mounted) return;
        setState(() => _errorMessage = 'Failed to save to database');
      }

    } catch (e) {
      print('❌ Upload failed: $e');
      if (!mounted) return;
      setState(() => _errorMessage = 'Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // ─── Complete Flow: Capture + Upload ───────────────────────────────────
  Future<void> _captureAndUpload() async {
    await _captureImage();

    // Wait a bit for location to be fetched
    await Future.delayed(const Duration(seconds: 1));

    if (_image != null && _position != null) {
      await _uploadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Image Preview ──────────────────────────────────────────────
            if (_image != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('No image captured'),
                ),
              ),

            const SizedBox(height: 16),

            // ── GPS Info ───────────────────────────────────────────────────
            if (_position != null)
              Text(
                'GPS: ${_position!.latitude.toStringAsFixed(4)}, '
                '${_position!.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12),
              ),

            const SizedBox(height: 16),

            // ── Buttons ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _captureImage,
                    icon: const Icon(Icons.camera),
                    label: const Text('Capture'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadImage,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isUploading ? null : _captureAndUpload,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Capture & Upload (Complete Flow)'),
            ),

            const SizedBox(height: 16),

            // ── Error Message ──────────────────────────────────────────────
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // ── Success: Show Uploaded Image ──────────────────────────────
            if (_uploadedImageUrl != null) ...[
              const SizedBox(height: 16),
              const Text(
                '✅ Uploaded successfully!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _uploadedImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}