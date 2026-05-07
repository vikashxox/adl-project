
# Loan Tracking Application

## Government of India — Internal System

A cross-platform mobile system for tracking government loan disbursements, managing beneficiaries, and enabling real-time verification workflows.

- **Version**: 1.0.0
- **Flutter**: 3.x
- **Backend**: Firebase
- **Platforms**: Android · iOS · Web · Desktop

## Overview

A three-tier role-based platform connecting loan beneficiaries, verification officers, and system administrators through a unified, real-time data pipeline.

### Beneficiary Portal
- Phone-based secure authentication
- View loan status, amounts & timelines
- GPS-tagged document photo uploads
- Offline queue with auto-sync on reconnect
- Full submission history with status tracking

### Officer Dashboard
- Review assigned beneficiary submissions
- Approve or reject with inline comments
- Manage assigned beneficiary portfolio
- Update verification status in real-time
- Search & filter by criteria

### Admin Control Panel
- System-wide metrics & analytics dashboard
- Add, edit and manage beneficiary records
- Assign officers to beneficiaries
- Broadcast push notifications globally
- Export data reports & configure settings

### Core Infrastructure
- Real-time Firestore sync across all devices
- Cloudinary CDN for secure image storage
- SQLite offline-first local storage
- FCM push notifications
- Multi-platform: Android, iOS, Web, Desktop

## Tech Stack

### Frontend
- **Flutter** ≥ 3.0.0
- **Dart** (Bundled)
- **Provider** (State management)
- **Material Design** (UI system)

### Firebase Services
- **Cloud Firestore** (NoSQL database)
- **Firebase Storage** (File backup)
- **Cloud Functions** (Serverless backend)
- **FCM** (Push notifications)

### Storage & Local
- **Cloudinary** (Primary CDN)
- **SQLite** (Offline database)
- **Shared Preferences** (Key-value storage)
- **Image Picker** (Camera/gallery access)

### Utilities
- **Geolocator** (GPS tagging)
- **Connectivity Plus** (Network monitoring)
- **HTTP** (API layer)
- **Intl** (Internationalization support)

## Prerequisites

Ensure the following tools are installed before proceeding with setup.

**Flutter SDK ≥ 3.0.0**  
Download from flutter.dev. Dart is included automatically with the Flutter SDK installation.

**Node.js ≥ 20**  
Required for Firebase Functions. Use nvm to manage Node versions cleanly across projects.

**Platform-specific tools**  
Android Studio (Android SDK) is required for Android. Xcode is required for iOS builds — macOS only.

**Firebase CLI**  
Install via `npm install -g firebase-tools`. Required for deploying functions and Firestore rules.

## Installation

Four steps from clone to running application.

### 1. Clone the repository
Download the project source and navigate into the directory.

```bash
git clone <repository-url>
cd adl-project
```

### 2. Install Flutter dependencies
Fetch all Dart/Flutter packages declared in `pubspec.yaml`.

```bash
flutter pub get
```

### 3. Install Firebase Functions dependencies
Navigate into the functions directory and install Node.js packages.

```bash
cd functions
npm install
cd ..
```

### 4. Configure Firebase
Create a Firebase project, enable Firestore and Storage, then place `google-services.json` in `android/app/`. The project is pre-configured for ID `loantrackerapp-37fba`.

## Configuration

Create a `.env` file in the project root with the following keys. Never commit this file to version control.

| Variable | Description | Required |
|----------|-------------|----------|
| `CLOUDINARY_CLOUD_NAME` | Your Cloudinary account cloud name | Required |
| `CLOUDINARY_API_KEY` | Cloudinary API key for authenticated requests | Required |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret — keep strictly private | Required |
| `CLOUDINARY_UPLOAD_PRESET` | Unsigned upload preset for direct client uploads | Required |
| `FIREBASE_PROJECT_ID` | Firebase project identifier (default: `loantrackerapp-37fba`) | Optional |

```env
# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset

# Firebase Configuration
FIREBASE_PROJECT_ID=loantrackerapp-37fba
```

## Running the App

Use `flutter run` for development, or target a specific platform with the `-d` flag.

### Platforms
- **Android**: `flutter run -d android`
- **iOS**: `flutter run -d ios`
- **Web**: `flutter run -d chrome`
- **Windows**: `flutter run -d windows`
- **Linux**: `flutter run -d linux`
- **macOS**: `flutter run -d macos`

### Build Commands
```bash
# Android release builds
flutter build apk --release
flutter build appbundle --release

# Web production build
flutter build web --release

# Deploy Firebase Functions
cd functions && npm run deploy
```

## Project Structure

```
adl-project/
├── lib/
│   ├── main.dart                 — App entry point
│   ├── firebase_options.dart     — Firebase config
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── role_selection_screen.dart
│   │   ├── beneficiary/          — Beneficiary UI
│   │   ├── officer/              — Officer UI
│   │   └── admin/                — Admin UI
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── cloudinary_service.dart
│   │   ├── firestore_upload_service.dart
│   │   ├── notification_service.dart
│   │   ├── upload_service.dart
│   │   └── connectivity_service.dart
│   ├── utils/                    — Theme, helpers
│   └── widgets/                  — Reusable components
├── functions/                    — Firebase Cloud Functions (Node.js)
├── android/ · ios/ · web/ · windows/
└── ...
```

## Troubleshooting

### Common Issues

**Firebase initialization fails**  
Verify `google-services.json` is placed in `android/app/` and matches your Firebase project ID exactly.

**Cloudinary uploads fail**  
Check that all four Cloudinary variables are set in `.env` and that the upload preset is configured as *unsigned* in your Cloudinary dashboard.

**GPS permissions denied**  
On Android, ensure `ACCESS_FINE_LOCATION` is declared in `AndroidManifest.xml`. On iOS, add the `NSLocationWhenInUseUsageDescription` key to `Info.plist`.

**Offline sync not working**  
Verify that Firestore offline persistence is enabled in your initialization code and that SQLite is not hitting its local storage quota.

---

**Loan Tracking Application**  
Proprietary software developed for the Government of India. All rights reserved.

- **Version**: 1.0.0+1
- **Updated**: May 2026
- **Project ID**: loantrackerapp-37fba
- **SDK**: Flutter ≥ 3.0.0

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
