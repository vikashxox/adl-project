
# Cloudinary + Firestore Upload Implementation

## Overview
This implementation provides a correct data flow for image uploads:
**Capture → Upload to Cloudinary → Save URL to Firestore → Display**

## Key Services

### 1. CloudinaryService (`cloudinary_upload_service.dart`)
- Uploads images to Cloudinary using unsigned preset
- Returns secure_url on success
- Throws exceptions on failure (never returns null)

### 2. FirestoreUploadService (`firestore_upload_service.dart`)
- Handles the complete upload flow: Cloudinary → Firestore
- NEVER stores local file paths in Firestore
- Only stores Cloudinary secure_url as `imageUrl`

## Correct Usage

### ✅ DO THIS:
```dart
// 1. Upload to Cloudinary first
final imageUrl = await cloudinaryService.uploadToCloudinary(imageFile);

// 2. Save ONLY the URL to Firestore
await firestore.collection('uploads').add({
  'imageUrl': imageUrl,  // ✅ Cloudinary URL
  // 'imagePath': NEVER include this field
  'loanId': loanId,
  'latitude': latitude,
  'longitude': longitude,
  // ... other metadata
});
```

### ❌ DON'T DO THIS:
```dart
// WRONG: Storing local file path
await firestore.collection('uploads').add({
  'imagePath': imageFile.path,  // ❌ LOCAL PATH - WRONG!
  'loanId': loanId,
  // ...
});
```

## Complete Flow Example

```dart
Future<void> uploadLoanProof() async {
  try {
    // Step 1: Capture image
    final imageFile = await pickImage();

    // Step 2: Get GPS location
    final position = await getCurrentPosition();

    // Step 3: Upload to Cloudinary
    final imageUrl = await cloudinaryService.uploadToCloudinary(imageFile);

    // Step 4: Save to Firestore (ONLY URL)
    await firestoreUploadService.saveUploadRecord(
      imageUrl: imageUrl,
      loanId: selectedLoanId,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now().toIso8601String(),
    );

    // Success! Now you can display the image using imageUrl
    print('Upload successful: $imageUrl');

  } catch (e) {
    print('Upload failed: $e');
  }
}
```

## Safety Features

- ✅ Null checks for image files
- ✅ Null checks for imageUrl
- ✅ Try-catch blocks around all operations
- ✅ Timeout handling for uploads
- ✅ Validation that URLs start with 'http'
- ✅ Debug print statements for troubleshooting

## UI Integration

```dart
// Show loading during upload
bool _isUploading = false;

// In button handler
setState(() => _isUploading = true);
try {
  await uploadLoanProof();
  // Show success message
} catch (e) {
  // Show error message
} finally {
  setState(() => _isUploading = false);
}
```

## Data Structure

Firestore document structure:
```json
{
  "imageUrl": "https://res.cloudinary.com/.../image.jpg",
  "loanId": "L-1001",
  "latitude": 12.3456,
  "longitude": 78.9012,
  "timestamp": "2024-01-01T10:00:00.000Z",
  "userId": "user123",
  "status": "pending",
  "createdAt": "2024-01-01T10:00:00.000Z"
}
```

## Important Notes

1. **NEVER store `file.path`** in Firestore
2. **ALWAYS store `imageUrl`** (Cloudinary secure_url)
3. **Upload to Cloudinary first**, then save to Firestore
4. **Handle offline scenarios** with local queuing
5. **Validate URLs** before saving to Firestore
6. **Use proper error handling** and user feedback

## Testing

To test the implementation:
1. Capture an image
2. Upload to Cloudinary
3. Verify Firestore contains `imageUrl` field (not `imagePath`)
4. Confirm the URL starts with `https://res.cloudinary.com`
5. Verify images display correctly using the stored URL
