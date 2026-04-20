import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service to manually trigger Cloud Function email notifications.
///
/// NOTE: The primary email trigger uses the Firestore-triggered Cloud Function
/// "onLoanCreated" which fires automatically whenever a document is added to
/// the "beneficiaries" collection. This service provides a callable fallback.
///
/// To use the callable function in Flutter you would normally add:
///   firebase_functions: ^5.x.x
/// to pubspec.yaml and call:
///   FirebaseFunctions.instance.httpsCallable('sendLoanAssignmentEmail')
///     .call({'loanId': loanId});
///
/// For now this service stores email log entries in Firestore so you can
/// track notification status without adding the functions package.
class NotificationService {
  NotificationService._();

  static final _db = FirebaseFirestore.instance;

  /// Logs an email notification request to Firestore.
  /// The Cloud Function trigger handles the actual sending automatically.
  static Future<void> logEmailNotification({
    required String loanId,
    required String officerId,
    required String officerEmail,
    required String beneficiaryName,
  }) async {
    try {
      await _db.collection('email_logs').add({
        'loanId': loanId,
        'officerId': officerId,
        'officerEmail': officerEmail,
        'beneficiaryName': beneficiaryName,
        'triggeredAt': FieldValue.serverTimestamp(),
        'status': 'auto_triggered', // Cloud Function handles this
      });
      debugPrint(
          'NotificationService: email log written for loan $loanId → $officerEmail');
    } catch (e) {
      debugPrint('NotificationService.logEmailNotification error: $e');
    }
  }
}
