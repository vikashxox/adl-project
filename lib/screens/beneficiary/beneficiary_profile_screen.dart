import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/app_session.dart';

/// Beneficiary profile screen — shows personal info and loan summary.
class BeneficiaryProfileScreen extends StatefulWidget {
  const BeneficiaryProfileScreen({super.key});

  @override
  State<BeneficiaryProfileScreen> createState() => _BeneficiaryProfileScreenState();
}

class _BeneficiaryProfileScreenState extends State<BeneficiaryProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final phone = AppSession.beneficiaryPhone;
    if (phone == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('beneficiaries')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        if (mounted) setState(() => _profile = snap.docs.first.data());
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppTheme.gray50, body: Center(child: CircularProgressIndicator()));
    }

    final name = _profile?['name'] ?? AppSession.beneficiaryName ?? 'N/A';
    final mobile = _profile?['phone'] ?? AppSession.beneficiaryPhone ?? 'N/A';
    final address = _profile?['address'] ?? 'N/A';
    final loanCount = '1'; // Currently singular per login
    final email = 'N/A';
    final aadhar = 'N/A';
    final amount = _profile?['loanAmount']?.toString() ?? AppSession.loanAmount?.toString() ?? '0';

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
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              36,
            ),
            child: Column(
              children: [
                // Back row
                Row(
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
                  ],
                ),
                const SizedBox(height: 24),
                // Avatar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Beneficiary', style: TextStyle(color: Colors.blue[100], fontSize: 14)),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Info Card
                  _buildCard(
                    title: 'Personal Information',
                    children: [
                      _buildInfoTile(Icons.phone, 'Mobile', mobile),
                      _buildInfoTile(Icons.email_outlined, 'Email', email),
                      _buildInfoTile(Icons.location_on_outlined, 'Address', address),
                      _buildInfoTile(Icons.credit_card, 'Aadhar', aadhar),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Loan Stats
                  _buildCard(
                    title: 'Loan Summary',
                    children: [
                      _buildInfoTile(Icons.account_balance, 'Active Loans', loanCount),
                      _buildInfoTile(Icons.currency_rupee, 'Total Amount', '₹$amount'),
                      _buildInfoTile(Icons.check_circle_outline, 'Repaid', '₹0'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Logout
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (_) => false),
                    style: AppTheme.outlinedFullWidth(sideColor: AppTheme.red600, foregroundColor: AppTheme.red600),
                    child: const Text('Logout'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
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

  Widget _buildInfoTile(IconData icon, String label, String value) {
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
