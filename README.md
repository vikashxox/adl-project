# Loan Tracking App

## Government of India Loan Tracking System

A comprehensive Flutter-based mobile application designed for tracking government loan disbursements and beneficiary submissions. The system supports role-based access for beneficiaries, officers, and administrators, enabling secure document uploads, verification workflows, and real-time monitoring.

## Features

### Beneficiary Features
- **Secure Login**: Phone number-based authentication
- **Loan Dashboard**: View loan status, amounts, and timelines
- **Document Upload**: GPS-tagged photo uploads for loan proof verification
- **Offline Support**: Queue uploads when offline, auto-sync when connected
- **Upload History**: Track all submissions with status updates
- **Profile Management**: Update personal information

### Officer Features
- **Verification Dashboard**: Review assigned beneficiary submissions
- **Document Review**: Approve/reject uploads with comments
- **Beneficiary Management**: View assigned beneficiaries
- **Status Updates**: Update loan verification status
- **Search & Filter**: Find submissions by various criteria

### Admin Features
- **System Overview**: Dashboard with key metrics and statistics
- **Beneficiary Management**: Add, edit, and manage beneficiary records
- **Officer Management**: Assign officers to beneficiaries
- **Loan Assignment**: Add extra loans to existing beneficiaries
- **Broadcast Notifications**: Send global app notifications
- **Data Export**: Generate and download analytics reports
- **System Settings**: Configure application parameters

### Core Features
- **Real-time Sync**: Firebase Firestore for live data synchronization
- **Cloud Storage**: Cloudinary integration for secure image storage
- **Offline Capability**: Local SQLite storage with sync mechanisms
- **GPS Integration**: Location tagging for upload verification
- **Push Notifications**: Firebase Cloud Messaging for alerts
- **Multi-platform**: Android, iOS, Web, Windows, Linux, macOS support

## Tech Stack

### Frontend
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management
- **Material Design**: UI components

### Backend & Services
- **Firebase Core**: App initialization
- **Cloud Firestore**: NoSQL database for real-time data
- **Firebase Storage**: File storage (backup)
- **Firebase Functions**: Serverless backend functions
- **Cloudinary**: Primary image storage and CDN
- **Firebase Cloud Messaging**: Push notifications

### Local Storage & Utilities
- **SQLite**: Local database for offline support
- **Shared Preferences**: Local key-value storage
- **Connectivity Plus**: Network monitoring
- **Geolocator**: GPS location services
- **Image Picker**: Camera/gallery image selection
- **HTTP**: API communications
- **Intl**: Internationalization support

## Prerequisites

- **Flutter SDK**: >=3.0.0 <4.0.0
- **Dart SDK**: Included with Flutter
- **Android Studio**: For Android development (with Android SDK)
- **Xcode**: For iOS development (macOS only)
- **Firebase CLI**: For deployment and functions
- **Node.js**: >=20 for Firebase functions
- **Git**: Version control

## Installation

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd adl-project
   ```

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Firebase Functions Dependencies**
   ```bash
   cd functions
   npm install
   cd ..
   ```

4. **Setup Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Firestore, Storage, and Cloud Functions
   - Download `google-services.json` for Android and place in `android/app/`
   - Configure Firebase options in `lib/firebase_options.dart` (already configured for project `loantrackerapp-37fba`)

## Configuration

### Environment Variables (.env)
Create a `.env` file in the root directory with the following variables:

```env
# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset

# Firebase Configuration (if needed)
FIREBASE_PROJECT_ID=loantrackerapp-37fba

# Other API Keys (if applicable)
```

### Firebase Setup
1. **Firestore Security Rules**: Deploy the rules in `firestore.rules`
2. **Storage Security Rules**: Deploy the rules in `storage.rules`
3. **Indexes**: Deploy Firestore indexes from `firestore.indexes.json`

### Cloudinary Setup
1. Create a Cloudinary account
2. Create an unsigned upload preset for secure uploads
3. Configure the preset to allow uploads from your app

## Running the App

### Development Mode
```bash
flutter run
```

### Specific Platform
```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# Linux
flutter run -d linux

# macOS
flutter run -d macos
```

### Firebase Emulators (for testing)
```bash
cd functions
npm run serve
```

## Building

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Desktop Platforms
```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release
```

## Deployment

### Firebase Functions
```bash
cd functions
npm run deploy
```

### Firebase Hosting (Web)
```bash
firebase init hosting
firebase deploy --only hosting
```

### Mobile App Stores
- **Android**: Upload AAB/APK to Google Play Console
- **iOS**: Upload to App Store Connect via Xcode or Transporter

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── role_selection_screen.dart
│   ├── beneficiary/
│   ├── officer/
│   └── admin/
├── services/                 # Business logic services
│   ├── api_service.dart
│   ├── app_session.dart
│   ├── cloudinary_service.dart
│   ├── connectivity_service.dart
│   ├── firebase_storage_service.dart
│   ├── firestore_upload_service.dart
│   ├── notification_service.dart
│   ├── storage_service.dart
│   ├── upload_history_query.dart
│   ├── upload_review_service.dart
│   └── upload_service.dart
├── utils/                    # Utilities
│   ├── app_theme.dart
│   └── firestore_image_url.dart
├── widgets/                  # Reusable UI components
└── ...

android/                      # Android platform code
ios/                          # iOS platform code
web/                          # Web platform code
windows/                      # Windows platform code
linux/                        # Linux platform code
macos/                        # macOS platform code
functions/                    # Firebase Cloud Functions
├── index.js
└── package.json
```

## API & Services Overview

### Upload Flow
1. **Capture**: Image picker with GPS location
2. **Upload**: Cloudinary for secure cloud storage
3. **Record**: Firestore for metadata and URL storage
4. **Sync**: Offline queue with auto-sync on connectivity

### Authentication
- Phone number-based authentication
- Role-based access control (Beneficiary/Officer/Admin)
- Session management with auto-logout

### Data Synchronization
- Real-time Firestore listeners
- Local SQLite for offline operations
- Conflict resolution on sync
- Network-aware UI updates

## Testing

```bash
# Run Flutter tests
flutter test

# Run Firebase function tests
cd functions
npm test
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Flutter's effective Dart guidelines
- Use `flutter analyze` to check code quality
- Run `flutter format` for consistent formatting

## Security Considerations

- All uploads are processed through Cloudinary for security
- Firebase security rules restrict data access
- GPS tagging prevents location spoofing
- Role-based permissions ensure data isolation
- Environment variables protect sensitive keys

## Troubleshooting

### Common Issues
- **Firebase initialization fails**: Check `google-services.json` placement and Firebase project configuration
- **Cloudinary uploads fail**: Verify `.env` variables and upload preset configuration
- **GPS permissions denied**: Ensure location permissions in app settings
- **Offline sync issues**: Check network connectivity and local storage

### Debug Mode
Enable debug logging in development:
```dart
// In main.dart
const bool isProduction = false;
if (!isProduction) {
  // Enable debug prints
}
```

## License

This project is proprietary software developed for the Government of India. All rights reserved.

## Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Refer to Firebase and Flutter documentation

---

**Version**: 1.0.0+1
**Last Updated**: May 2026
**Platform Support**: Android, iOS, Web, Desktop
