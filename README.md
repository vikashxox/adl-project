
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
- Phone-based OTP authentication
- Loan dashboard with status and timelines
- GPS-tagged, camera-captured document uploads
- Offline upload queue with auto-sync on reconnect
- Submission history with per-upload verification status

### Officer Dashboard
- Review submissions assigned to the logged-in officer
- Approve or reject uploads with comments
- View full beneficiary & loan details
- Real-time status updates via Firestore
- Search and filter submission data

### Admin Control Panel
- System overview with key metrics
- Add / manage beneficiaries and officers
- Assign officers to beneficiaries
- Broadcast FCM notifications to all users
- Export reports and configure system settings

### Core Infrastructure
- Realtime sync via Cloud Firestore
- Cloudinary for secure image hosting
- SQLite offline persistence
- Firebase Cloud Messaging (FCM) push notifications
- Firebase Cloud Functions for automated email notifications
- Cross-platform Flutter support

---

## System Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                         ADMIN                                   │
│  1. Creates beneficiary record  ─────────────────────────────┐  │
│  2. Creates officer record                                   │  │
│  3. Assigns officer to beneficiary  ──── Firestore write ────┤  │
└──────────────────────────────────────────────────────────────┼──┘
                                                               │
                        Cloud Function: onLoanCreated          │
                        Triggers on new "beneficiaries" doc ◄──┘
                        Reads officer email from Firestore
                        Sends assignment email via Nodemailer
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        OFFICER                                  │
│  1. Receives email: "New loan assigned"                         │
│  2. Logs in with credentials                                    │
│  3. Sees beneficiary list on dashboard                          │
│  4. Opens submission → Approve / Reject with comment            │
│  5. Status updates instantly in Firestore                       │
└──────────────────────────────────────────────────────────────┬──┘
                                                               │
                                              Firestore update │
                                                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BENEFICIARY                                │
│  1. Logs in via phone OTP                                       │
│  2. Views loan details and deadline                             │
│  3. Captures photo (GPS coordinates embedded automatically)     │
│  4. Upload flow:                                                │
│       Online  → Cloudinary upload → Firestore doc created       │
│       Offline → Queued in SQLite  → Auto-synced when online     │
│  5. Receives verification status (Pending / Approved / Rejected)│
│  6. Views full upload history with AI fraud score              │
└─────────────────────────────────────────────────────────────────┘
```

### Upload Verification Sub-Flow

```
Beneficiary captures photo
        │
        ▼
GPS coordinates attached  ──► gps_camera_upload_screen.dart
        │
        ▼
Online? ──No──► SQLite offline queue (storage_service.dart)
        │              │
       Yes      Connectivity restored
        │              │
        └──────────────┘
        │
        ▼
Cloudinary upload (cloudinary_service.dart)
        │
        ▼
Firestore doc created under beneficiaries/{id}/uploads
        │
        ├── status: "pending"
        ├── imageUrl (Cloudinary)
        ├── gpsLat / gpsLng
        └── timestamp
        │
        ▼
Officer reviews in verification_detail_screen.dart
        │
   ┌────┴────┐
  APPROVE  REJECT
   │          │
   └────┬─────┘
        │
   Firestore doc updated
        │
        ▼
Beneficiary sees result in upload_history_detail_screen.dart
```

### Cloud Functions

| Function | Trigger | Action |
|---|---|---|
| `onLoanCreated` | Firestore `beneficiaries/{loanId}` created | Fetches officer email → sends HTML assignment email via Gmail SMTP |
| `sendLoanAssignmentEmail` | HTTPS Callable | Manual re-trigger of assignment email for a given `loanId` |

---

## Tech Stack

### Frontend
| Layer | Technology |
|---|---|
| Framework | Flutter / Dart |
| State management | Provider |
| UI | Material Design 3 |
| Local storage | SQLite (`sqflite`) + Shared Preferences |
| Offline detection | Connectivity Plus |
| Location | Geolocator |
| Camera | Image Picker |

### Backend
| Service | Purpose |
|---|---|
| Cloud Firestore | Primary database & realtime sync |
| Firebase Storage | Binary asset fallback |
| Cloudinary | Primary image CDN & storage |
| Firebase Cloud Functions (Node.js) | Server-side triggers & email |
| Firebase Cloud Messaging | Push notifications |
| Gmail SMTP (via Nodemailer) | Transactional email |

---

## Firestore Data Model

```
firestore/
├── beneficiaries/{loanId}           — Loan & beneficiary details
│   ├── name, phone, loanAmount
│   ├── loanPurpose, village, district, state
│   ├── assignedOfficerId, assignedOfficerName
│   ├── disbursementDate, deadline
│   └── uploads/{uploadId}           — Sub-collection
│       ├── imageUrl (Cloudinary)
│       ├── status  (pending | approved | rejected)
│       ├── gpsLat, gpsLng
│       ├── timestamp
│       └── reviewComment
│
└── officers/{officerId}             — Officer profiles
    ├── name, email, phone
    └── assignedBeneficiaries[]
```

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

### Firebase Setup

1. Create a Firebase project.
2. Enable **Firestore**, **Storage**, **Cloud Functions**, and **Authentication**.
3. Add `google-services.json` to `android/app/`.
4. Verify `lib/firebase_options.dart` matches your Firebase project.

### Cloud Functions Secrets

```bash
firebase functions:secrets:set GMAIL_USER
firebase functions:secrets:set GMAIL_PASS
```

---

## Configuration

Create a `.env` file in the project root. **Never commit this file.**

| Variable | Description | Required |
|---|---|---|
| `CLOUDINARY_CLOUD_NAME` | Cloudinary account cloud name | ✅ |
| `CLOUDINARY_API_KEY` | Cloudinary API key | ✅ |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | ✅ |
| `CLOUDINARY_UPLOAD_PRESET` | Unsigned upload preset | ✅ |
| `FIREBASE_PROJECT_ID` | Firebase project ID | Optional |

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
FIREBASE_PROJECT_ID=loantrackerapp-37fba
```

---

## Running the App

```bash
# Development
flutter run                   # default connected device
flutter run -d android
flutter run -d chrome
flutter run -d windows

# Release builds
flutter build apk --release
flutter build appbundle --release
flutter build web --release

# Deploy Cloud Functions
cd functions && npm run deploy
```

---

## Project Structure

```
adl-project/
│
├── lib/
│   ├── main.dart                          — App entry point & Firebase init
│   ├── firebase_options.dart              — Auto-generated Firebase config
│   │
│   ├── screens/
│   │   ├── splash_screen.dart             — Loading / auth gate
│   │   ├── role_selection_screen.dart     — Beneficiary / Officer / Admin picker
│   │   │
│   │   ├── beneficiary/
│   │   │   ├── beneficiary_login_screen.dart
│   │   │   ├── beneficiary_dashboard_screen.dart
│   │   │   ├── beneficiary_profile_screen.dart
│   │   │   ├── loan_details_screen.dart
│   │   │   ├── gps_camera_upload_screen.dart   — Core upload flow
│   │   │   ├── pending_uploads_screen.dart     — Offline queue viewer
│   │   │   ├── history_screen.dart
│   │   │   ├── upload_history_detail_screen.dart
│   │   │   └── submission_success_screen.dart
│   │   │
│   │   ├── officer/
│   │   │   ├── officer_login_screen.dart
│   │   │   ├── officer_dashboard_screen.dart
│   │   │   ├── officer_profile_screen.dart
│   │   │   └── verification_detail_screen.dart — Approve / Reject UI
│   │   │
│   │   └── admin/
│   │       ├── admin_dashboard_screen.dart
│   │       ├── admin_data_entry_screen.dart    — Add beneficiary
│   │       ├── add_extra_loan_screen.dart
│   │       ├── add_officer_screen.dart
│   │       ├── admin_beneficiaries_screen.dart
│   │       ├── view_beneficiaries_screen.dart
│   │       ├── beneficiary_details_screen.dart
│   │       ├── view_officers_screen.dart
│   │       ├── officer_details_screen.dart
│   │       ├── admin_uploads_screen.dart
│   │       ├── admin_broadcast_screen.dart     — FCM broadcast
│   │       ├── admin_export_report_screen.dart
│   │       ├── admin_settings_screen.dart
│   │       └── admin_profile_screen.dart
│   │
│   ├── services/
│   │   ├── api_service.dart               — HTTP helpers
│   │   ├── app_session.dart               — Session / auth state
│   │   ├── cloudinary_service.dart        — Image upload to Cloudinary
│   │   ├── firebase_storage_service.dart  — Firebase Storage fallback
│   │   ├── firestore_upload_service.dart  — Write upload docs to Firestore
│   │   ├── upload_service.dart            — Orchestrates upload pipeline
│   │   ├── storage_service.dart           — SQLite offline queue
│   │   ├── connectivity_service.dart      — Network state monitoring
│   │   ├── notification_service.dart      — FCM token & notification handler
│   │   ├── upload_review_service.dart     — Officer approve/reject writes
│   │   ├── upload_history_query.dart      — Firestore query helpers
│   │   └── loan_proof_upload_usage_example.dart
│   │
│   ├── utils/
│   │   ├── app_theme.dart                 — Global colour & text theme
│   │   ├── firestore_image_url.dart       — URL resolution helpers
│   │   ├── firestore_query_helpers.dart   — Reusable Firestore queries
│   │   └── firestore_test.dart
│   │
│   └── widgets/
│       ├── notification_bell.dart         — App bar notification icon
│       ├── upload_review_actions.dart     — Approve/Reject button row
│       ├── upload_debug_widget.dart
│       └── upload_example_widget.dart
│
├── functions/                             — Firebase Cloud Functions (Node.js)
│   ├── index.js                           — onLoanCreated · sendLoanAssignmentEmail
│   └── package.json
│
├── android/ · ios/ · web/ · windows/ · linux/ · macos/
├── firebase.json                          — Firebase project config
├── firestore.indexes.json                 — Composite index definitions
├── storage.rules                          — Firebase Storage security rules
├── pubspec.yaml
└── .env                                   — Local secrets (git-ignored)
```

---

## Troubleshooting

### Common Issues

**Firebase initialization fails**  
Verify `google-services.json` is placed in `android/app/` and matches your Firebase project ID exactly.

**Cloudinary uploads fail**  
Check that all four Cloudinary variables are set in `.env` and that the upload preset is configured as *unsigned* in your Cloudinary dashboard.

**GPS permissions denied**  
On Android, ensure `ACCESS_FINE_LOCATION` is declared in `AndroidManifest.xml`. On iOS, add `NSLocationWhenInUseUsageDescription` to `Info.plist`.

**Offline sync not working**  
Verify that Firestore offline persistence is enabled and that SQLite is not hitting its local storage quota.

**Cloud Function email not sending**  
Confirm `GMAIL_USER` and `GMAIL_PASS` secrets are set via `firebase functions:secrets:set`. The Gmail account must have an App Password enabled (2FA required).
