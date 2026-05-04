// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDvbWnmWJOXtkJiUF7EkN4Tz4R-uuXhq7I',
    authDomain: 'loantrackerapp-37fba.firebaseapp.com',
    projectId: 'loantrackerapp-37fba',
    storageBucket: 'loantrackerapp-37fba.firebasestorage.app',
    messagingSenderId: '19148609455',
    appId: '1:19148609455:web:0000000000000000',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvbWnmWJOXtkJiUF7EkN4Tz4R-uuXhq7I',
    appId: '1:19148609455:android:2ac9e11e24092c69d2815a',
    messagingSenderId: '19148609455',
    projectId: 'loantrackerapp-37fba',
    storageBucket: 'loantrackerapp-37fba.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvbWnmWJOXtkJiUF7EkN4Tz4R-uuXhq7I',
    appId: '1:19148609455:ios:0000000000000000',
    messagingSenderId: '19148609455',
    projectId: 'loantrackerapp-37fba',
    storageBucket: 'loantrackerapp-37fba.firebasestorage.app',
    iosBundleId: 'com.example.loan_tracking_app',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDvbWnmWJOXtkJiUF7EkN4Tz4R-uuXhq7I',
    appId: '1:19148609455:desktop:0000000000000000',
    messagingSenderId: '19148609455',
    projectId: 'loantrackerapp-37fba',
    storageBucket: 'loantrackerapp-37fba.firebasestorage.app',
  );
  static const FirebaseOptions linux = windows;
}
