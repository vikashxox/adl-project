import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Full beneficiary details view showing personal info and loan details.
class BeneficiaryDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> beneficiary;

  const BeneficiaryDetailsScreen({super.key, required this.beneficiary});

  String _formatAmount(int amt) {
    return amt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Color get _statusColor {
    final status = beneficiary['loanStatus'] ?? beneficiary['status'] ?? 'pending';
    switch (status) {
      case 'approved': return AppTheme.green600;
      case 'pending': return AppTheme.amber600;
      case 'rejected': return AppTheme.red600;
      default: return AppTheme.gray500;
    }
  }

  Color get _statusBg {
    final status = beneficiary['loanStatus'] ?? beneficiary['status'] ?? 'pending';
    switch (status) {
      case 'approved': return const Color(0xFFF0FDF4);
      case 'pending': return const Color(0xFFFFFBEB);
      case 'rejected': return const Color(0xFFFEF2F2);
      default: return AppTheme.gray100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = beneficiary['name'] as String? ?? 'Unknown';
    final mobile = (beneficiary['mobile'] ?? beneficiary['phone']) as String? ?? 'N/A';
    final address = beneficiary['address'] as String? ?? 'N/A';
    final loanId = beneficiary['loanId'] as String? ?? 'N/A';
    final loanAmountRaw = beneficiary['loanAmount'] ?? 0;
    final loanAmount = loanAmountRaw is int ? loanAmountRaw : int.tryParse(loanAmountRaw.toString()) ?? 0;
    final loanStatus = (beneficiary['loanStatus'] ?? beneficiary['status']) as String? ?? 'pending';
    final loanPurpose = beneficiary['loanPurpose'] as String? ?? 'N/A';

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Back', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(loanId, style: TextStyle(color: Colors.blue[100], fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Personal Info
                  _buildSection(
                    title: 'Personal Information',
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppTheme.blue600,
                    children: [
                      _infoRow(Icons.person, 'Name', name),
                      _infoRow(Icons.phone, 'Mobile', mobile),
                      _infoRow(Icons.location_on_outlined, 'Address', address),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                          child: const Icon(Icons.currency_rupee, size: 28, color: AppTheme.blue600),
                        ),
                        const SizedBox(height: 12),
                        Text('₹${_formatAmount(loanAmount)}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.gray800)),
                        const SizedBox(height: 4),
                        const Text('Loan Amount', style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            loanStatus[0].toUpperCase() + loanStatus.substring(1),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Loan Details
                  _buildSection(
                    title: 'Loan Details',
                    iconBg: const Color(0xFFF0FDF4),
                    iconColor: AppTheme.green600,
                    children: [
                      _infoRow(Icons.badge, 'Loan ID', loanId),
                      _infoRow(Icons.gps_fixed, 'Purpose', loanPurpose),
                      _infoRow(Icons.info_outline, 'Status', loanStatus[0].toUpperCase() + loanStatus.substring(1)),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Color iconBg = const Color(0xFFEFF6FF),
    Color iconColor = AppTheme.blue600,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray800)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppTheme.blue600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
