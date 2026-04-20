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
  
  // Beneficiary specific global state
  static String? beneficiaryPhone;
  static String? beneficiaryName;
  static String? loanId;
  static int? loanAmount;
  static String? loanPurpose;
  static String? disbursedDate;
  static String? deadline;
  static String? loanStatus;

  static AppRole get role => _role;
  static String? get officerId => _officerId;

  /// Only field officers may approve/reject uploads (not system admins).
  static bool get canReviewUploads =>
      _role == AppRole.officer &&
      _officerId != null &&
      _officerId!.trim().isNotEmpty;

  static void setBeneficiaryData({
    required String phone,
    required String name,
    required String lId,
    required int amount,
    required String purpose,
    required String dDate,
    required String deadlineDate,
    required String status,
  }) {
    _role = AppRole.beneficiary;
    _officerId = null;
    beneficiaryPhone = phone;
    beneficiaryName = name;
    loanId = lId;
    loanAmount = amount;
    loanPurpose = purpose;
    disbursedDate = dDate;
    deadline = deadlineDate;
    loanStatus = status;
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
    beneficiaryPhone = null;
    beneficiaryName = null;
    loanId = null;
    loanAmount = null;
    loanPurpose = null;
    disbursedDate = null;
    deadline = null;
    loanStatus = null;
  }
}
