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
  List<Map<String, dynamic>> _loans = [];
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
          .get();

      if (snap.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _loans = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
            _profile = _loans.first;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }
  
  String _formatAmount(int amt) {
    return amt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppTheme.gray50, body: Center(child: CircularProgressIndicator()));
    }

    final name = _profile?['name'] ?? AppSession.beneficiaryName ?? 'N/A';
    final mobile = _profile?['phone'] ?? AppSession.beneficiaryPhone ?? 'N/A';
    final address = _profile?['address'] ?? 'N/A';
    
    final loanCount = _loans.length.toString();
    final totalAmount = _loans.fold<int>(0, (sum, l) {
      final amt = l['loanAmount'] ?? 0;
      if (amt is int) return sum + amt;
      return sum + (int.tryParse(amt.toString()) ?? 0);
    });

    final email = 'N/A';
    final aadhar = 'N/A';

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

                  // Loan Stats Summary
                  _buildCard(
                    title: 'Loan Summary',
                    children: [
                      _buildInfoTile(Icons.account_balance, 'Active Loans', loanCount),
                      _buildInfoTile(Icons.currency_rupee, 'Total Amount', '₹${_formatAmount(totalAmount)}'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Individual Loans List
                  if (_loans.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('My Active Loans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray800)),
                    ),
                    const SizedBox(height: 12),
                    ..._loans.map((loan) {
                      final status = loan['status'] ?? loan['loanStatus'] ?? 'pending';
                      final lAmountRaw = loan['loanAmount'] ?? 0;
                      final lAmount = lAmountRaw is int ? lAmountRaw : int.tryParse(lAmountRaw.toString()) ?? 0;
                      final isApproved = status == 'approved';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${loan['loanId'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.gray800, fontSize: 14)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10)),
                                  child: Text((status as String).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isApproved ? AppTheme.green600 : AppTheme.amber600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            _buildMiniRow(Icons.currency_rupee, 'Amount: ₹${_formatAmount(lAmount)}'),
                            const SizedBox(height: 4),
                            _buildMiniRow(Icons.gps_fixed, 'Purpose: ${loan['loanPurpose'] ?? 'N/A'}'),
                            const SizedBox(height: 4),
                            _buildMiniRow(Icons.person, 'Officer: ${loan['assignedOfficer'] ?? 'Unassigned'}'),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],

                  // Logout
                  OutlinedButton(
                    onPressed: () {
                      AppSession.clear();
                      Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (_) => false);
                    },
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

  Widget _buildMiniRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.gray500),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.gray700)),
      ],
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
