
# Loan Tracking Application

## Government of India — Internal System

A cross-platform loan tracking platform for managing beneficiaries, verification officers, and administrators using real-time data, GPS-enabled uploads, and offline sync.

- **Version:** 1.0.0+1
- **Flutter:** 3.x
- **Backend:** Firebase + Cloudinary
- **Platforms:** Android · iOS · Web · Windows · Linux · macOS

---

## Overview

A three-tier role-based application that connects loan beneficiaries, field officers, and system administrators with a secure document upload and verification workflow.

### Beneficiary Portal
- Phone-based authentication
- Loan dashboard with status and timelines
- GPS-tagged document uploads
- Offline upload queue and auto-sync
- Submission history with verification status

### Officer Dashboard
- Review assigned beneficiary submissions
- Approve or reject uploads with comments
- Manage assigned beneficiary portfolio
- Update verification status in real time
- Search and filter submission data

### Admin Control Panel
- System overview with key metrics
- Manage beneficiaries and officer assignments
- Broadcast notifications to all users
- Export reports and configure system settings

### Core Infrastructure
- Realtime sync via Firestore
- Cloudinary for secure image hosting
- SQLite offline persistence
- FCM push notifications
- Cross-platform support

---

## Tech Stack

### Frontend
- Flutter
- Dart
- Provider
- Material Design

### Backend
- Firebase Core
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions
- Firebase Cloud Messaging

### Storage & Utilities
- Cloudinary
- SQLite
- Shared Preferences
- Connectivity Plus
- Geolocator
- Image Picker
- HTTP
- Intl

---

## Prerequisites

- Flutter SDK `>=3.0.0 <4.0.0`
- Node.js `>=20`
- Firebase CLI
- Android Studio (Android builds)
- Xcode (iOS builds on macOS)
- Git

---

## Installation

```bash
git clone <repository-url>
cd adl-project
flutter pub get
cd functions
npm install
cd ..
```

### Firebase setup

1. Create a Firebase project.
2. Enable Firestore, Storage, and Cloud Functions.
3. Add `google-services.json` to `android/app/`.
4. Verify `lib/firebase_options.dart` matches your Firebase project.

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


