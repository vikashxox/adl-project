
# 📱 Loan Tracking Application

A comprehensive cross-platform loan tracking system designed for seamless integration between beneficiaries, verification officers, and administrators with GPS-enabled uploads, real-time synchronization, and offline support.

✨ **Core Ecosystem**

🎯 **Beneficiary Module**
- Phone-based OTP authentication
- Loan dashboard with status and deadlines
- GPS-tagged document uploads with camera capture
- Offline upload queue with auto-sync
- Submission history with verification status

👮 **Officer Dashboard**
- Real-time submission review and assignment
- Approve/reject uploads with comments
- Full beneficiary and loan detail access
- Live status updates via Firestore
- Search and filter capabilities

⚙️ **Admin Control Panel**
- System overview with key metrics
- Manage beneficiaries and officers
- Assign officers to beneficiary accounts
- Broadcast notifications to all users
- Export reports and system configuration

🔧 **Core Infrastructure**
- Cloud Firestore for real-time database
- Cloudinary for secure image storage
- SQLite offline persistence
- Firebase Cloud Messaging (FCM)
- Cloud Functions for automation
- Cross-platform Flutter support

---

## Design Philosophy

Loan Tracking Application features a clean, intuitive interface that prioritizes user accessibility while maintaining security:

- **User-Centric Design:** Simplified workflows optimized for field officers and rural beneficiaries
- **Offline-First:** Seamless operation in low-connectivity zones with automatic sync
- **Real-Time Tracking:** Instant status updates across all user roles

---

## Tech Stack

**Frontend:** Flutter & Dart (High-performance UI rendering)
**Backend:** Firebase (Firestore, Auth, Cloud Functions, Cloud Messaging)
**Storage:** Cloudinary (Secure image hosting) + SQLite (Local persistence)
**Navigation:** Open Source Routing Machine (OSRM)
**Additional:** GPS Integration, Firebase Cloud Messaging

---

## Getting Started

**Hardware & Software Requirements**

Key Accounts/Prerequisites:
- Firebase Account with Firestore and Auth enabled
- Cloudinary Account for image uploads

Software Requirements:
- Operating System: Windows, macOS, Linux (Development)
- Flutter SDK: Version 3.10 or higher
- Dart SDK: Included with Flutter
- Database: Firebase Cloud Firestore

Development Tools:
- Dart: Object-oriented application development
- Flutter: Cross-platform UI toolkit
- Firebase Services: Authentication and Database
- Cloudinary: Cloud-based media management

---

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/[username]/adl-project.git
   ```

2. Setup Firebase:
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to respective directories

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the application:
   ```
   flutter run --no-impeller
   ```

