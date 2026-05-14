import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore queries for the `uploads` collection.
///
/// ## Required composite indexes (deploy with Firebase CLI: `firebase deploy --only firestore:indexes`)
/// or create them when the console shows a link in the error.
///
/// 1. **Beneficiary history** — [beneficiaryUploadsStream]
///    - `role` Ascending + `createdAt` Descending
///
/// 2. **Admin / officer list with status filter** — [uploadsStreamForStaff]
///    - `status` Ascending + `createdAt` Descending
///
/// Single-field `createdAt` ordering alone does **not** need a custom index when
/// there is no `where` clause (see "all" filter).
class UploadHistoryQuery {
  UploadHistoryQuery._();

  static final _uploads = FirebaseFirestore.instance.collection('uploads');

  /// Beneficiary-only uploads, filtered by phone, newest first.
  ///
  /// Query: `where phone == phone` + `orderBy createdAt desc`
  static Stream<QuerySnapshot<Map<String, dynamic>>> beneficiaryUploadsStream(String phone) {
    return _uploads
        .where('phone', isEqualTo: phone)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Admin (read-only) or officer (review) — all uploads or filtered by [statusFilter].
  ///
  /// * `statusFilter == 'all'` → `orderBy('createdAt', descending: true)` only.
  /// * else → `where('status', isEqualTo: …)` + same `orderBy` (needs composite index).
  static Query<Map<String, dynamic>> uploadsQueryForStaff({required String statusFilter}) {
    if (statusFilter == 'all') {
      return _uploads.orderBy('createdAt', descending: true);
    }
    return _uploads
        .where('status', isEqualTo: statusFilter)
        .orderBy('createdAt', descending: true);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> allUploadsStream({int? limit}) {
    Query<Map<String, dynamic>> q = _uploads.orderBy('createdAt', descending: true);
    if (limit != null) q = q.limit(limit);
    return q.snapshots();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> uploadDocumentStream(String docId) {
    return _uploads.doc(docId).snapshots();
  }
}
