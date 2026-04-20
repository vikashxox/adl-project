/// In-memory session for the current app role (no backend auth in this build).
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

  static AppRole get role => _role;
  static String? get officerId => _officerId;

  /// Only field officers may approve/reject uploads (not system admins).
  static bool get canReviewUploads =>
      _role == AppRole.officer &&
      _officerId != null &&
      _officerId!.trim().isNotEmpty;

  static void setBeneficiary() {
    _role = AppRole.beneficiary;
    _officerId = null;
  }

  static void setOfficer(String id) {
    _role = AppRole.officer;
    _officerId = id.trim();
  }

  /// System admin dashboard (view all data, no upload approval).
  static void setAdmin() {
    _role = AppRole.admin;
    _officerId = null;
  }

  static void clear() {
    _role = AppRole.beneficiary;
    _officerId = null;
  }
}
