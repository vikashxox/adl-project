import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_session.dart';

/// Handles Firebase Phone Auth (beneficiary) and
/// Firestore username/password auth (officer/admin).
class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ─── Phone Auth (Beneficiary) ─────────────────────────────────────────────

  /// Sends an OTP to [phoneNumber] (must include country code, e.g. +919876543210).
  /// [onCodeSent] receives the verificationId to use in [verifyOtp].
  /// [onError] receives a human-readable message on failure.
  static Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
    void Function(PhoneAuthCredential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        onAutoVerified?.call(credential);
      },
      verificationFailed: (e) {
        onError(_friendlyAuthError(e));
      },
      codeSent: (verificationId, _) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Verifies [otp] against [verificationId].
  /// On success, fetches the user's Firestore doc and updates [AppSession].
  /// Returns an error message string, or null on success.
  static Future<String?> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return 'Sign-in failed. Please try again.';

      // Confirm the Firestore doc exists for this user (role check optional here).
      await _db.collection('users').doc(user.uid).get();

      AppSession.setBeneficiary(userId: user.uid);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _friendlyAuthError(e);
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Username / Password Auth (Officer / Admin) ───────────────────────────

  /// Looks up [username] in `users` collection and validates [password].
  /// Returns the role string ('officer' | 'admin') on success,
  /// or null on failure (also sets [errorOut]).
  static Future<({String role, String uid})?> loginWithCredentials({
    required String username,
    required String password,
    required void Function(String) onError,
  }) async {
    try {
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        onError('Username not found.');
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();
      final storedPassword = data['password'] as String? ?? '';
      final role = data['role'] as String? ?? '';

      if (storedPassword != password) {
        onError('Incorrect password.');
        return null;
      }

      if (role != 'officer' && role != 'admin') {
        onError('This account does not have officer or admin access.');
        return null;
      }

      // Update AppSession
      if (role == 'admin') {
        AppSession.setAdmin();
      } else {
        AppSession.setOfficer(doc.id);
      }

      return (role: role, uid: doc.id);
    } catch (e) {
      onError('Login error: $e');
      return null;
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await _auth.signOut();
    AppSession.clear();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Include country code (e.g. +91…).';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Please check and retry.';
      case 'session-expired':
        return 'OTP expired. Please request a new one.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }
}
