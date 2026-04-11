/// In-memory session for the current app role.
/// Set when the user completes role-specific login.
enum AppRole {
  beneficiary,
  officer,
  admin,
}

class AppSession {
  AppSession._();

  static AppRole _role = AppRole.beneficiary;
  static String? _officerId;
  static String? _userId;

  static AppRole get role => _role;
  static String? get officerId => _officerId;

  /// UID of the currently logged-in user (set for all roles).
  static String? get userId => _userId;

  /// Only field officers may approve/reject uploads (not system admins).
  static bool get canReviewUploads =>
      _role == AppRole.officer &&
      _officerId != null &&
      _officerId!.trim().isNotEmpty;

  static void setBeneficiary({required String userId}) {
    _role = AppRole.beneficiary;
    _userId = userId;
    _officerId = null;
  }

  static void setOfficer(String id) {
    _role = AppRole.officer;
    _officerId = id.trim();
    _userId = id.trim();
  }

  /// System admin dashboard (view all data, no upload approval).
  static void setAdmin() {
    _role = AppRole.admin;
    _officerId = null;
    _userId = null;
  }

  static void clear() {
    _role = AppRole.beneficiary;
    _officerId = null;
    _userId = null;
  }
}
