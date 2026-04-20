import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import 'beneficiary_details_screen.dart';

/// Shows full officer details and their assigned beneficiaries list.
class OfficerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> officer;

  const OfficerDetailsScreen({super.key, required this.officer});

  @override
  State<OfficerDetailsScreen> createState() => _OfficerDetailsScreenState();
}

class _OfficerDetailsScreenState extends State<OfficerDetailsScreen> {
  List<Map<String, dynamic>> _beneficiaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedBeneficiaries();
  }

  Future<void> _fetchAssignedBeneficiaries() async {
    final username = widget.officer['username'] as String?;
    if (username == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('beneficiaries')
          .where('assignedOfficer', isEqualTo: username)
          .get();

      if (mounted) {
        setState(() {
          _beneficiaries = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final officer = widget.officer;
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
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
                      child: const Icon(Icons.manage_accounts, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(officer['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(officer['role'] as String, style: TextStyle(color: Colors.green[100], fontSize: 13)),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Officer Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray800)),
                        const SizedBox(height: 16),
                        _infoRow(Icons.badge, 'Officer ID', officer['id'] as String),
                        _infoRow(Icons.phone, 'Phone', officer['phone'] as String),
                        _infoRow(Icons.email_outlined, 'Email', officer['email'] as String),
                        _infoRow(Icons.location_city, 'District', officer['district'] as String),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Assigned Beneficiaries Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Assigned Beneficiaries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray800)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(20)),
                        child: Text('${_beneficiaries.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.green600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Beneficiaries List
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (_beneficiaries.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No beneficiaries assigned.', style: TextStyle(color: AppTheme.gray500))))
                  else
                    ..._beneficiaries.map((b) {
                      final loanStatus = b['status'] as String? ?? 'pending';
                      final loanAmt = b['loanAmount'] ?? 0;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BeneficiaryDetailsScreen(beneficiary: b)),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.gray200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person, size: 22, color: AppTheme.blue600),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b['name'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
                                    const SizedBox(height: 2),
                                    Text(b['loanId'] as String? ?? 'N/A', style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${_formatAmount(loanAmt is int ? loanAmt : int.tryParse(loanAmt.toString()) ?? 0)}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray700),
                                        ),
                                        const SizedBox(width: 8),
                                        _statusBadge(loanStatus),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppTheme.gray400),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
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
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppTheme.green600),
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

  Widget _statusBadge(String status) {
    final isApproved = status == 'approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isApproved ? AppTheme.green600 : AppTheme.amber600),
      ),
    );
  }

  String _formatAmount(int amt) {
    return amt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}
