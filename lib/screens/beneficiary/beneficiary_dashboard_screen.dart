import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/connectivity_service.dart';
import 'loan_details_screen.dart';
import 'beneficiary_profile_screen.dart';
import '../../services/app_session.dart';

/// Beneficiary Dashboard — shows loan summary, status, action buttons,
/// pending uploads badge, and timeline.
class BeneficiaryDashboardScreen extends StatefulWidget {
  const BeneficiaryDashboardScreen({super.key});

  @override
  State<BeneficiaryDashboardScreen> createState() => _BeneficiaryDashboardScreenState();
}

class _BeneficiaryDashboardScreenState extends State<BeneficiaryDashboardScreen> {
  final _storage = StorageService();
  final _connectivity = ConnectivityService();
  int _pendingCount = 0;
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _connectivity.addListener(_onConnectivityChanged);
    _connectivity.onSyncComplete = _loadCounts;
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    _connectivity.onSyncComplete = null;
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCounts() async {
    final counts = await _storage.getUploadCounts();
    if (mounted) {
      setState(() {
        _pendingCount = counts['pending'] ?? 0;
        _uploadedCount = counts['uploaded'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final beneficiaryName = AppSession.beneficiaryName ?? 'Unknown User';

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.person, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back', style: TextStyle(color: Colors.blue[100], fontSize: 11)),
                      Text(beneficiaryName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Connectivity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _connectivity.isOnline ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _connectivity.isOnline ? 'ONLINE' : 'OFFLINE',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Profile icon
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BeneficiaryProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.account_circle, size: 24, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Loans List
                  StreamBuilder<QuerySnapshot>(
                    stream: AppSession.beneficiaryPhone != null && AppSession.beneficiaryPhone!.isNotEmpty
                        ? FirebaseFirestore.instance.collection('beneficiaries').where('phone', isEqualTo: AppSession.beneficiaryPhone).snapshots()
                        : null,
                    builder: (context, snapshot) {
                      if (AppSession.beneficiaryPhone == null || AppSession.beneficiaryPhone!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: Text('Please log in securely to view your loans', style: TextStyle(color: AppTheme.gray500))),
                        );
                      }

                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: Text('Error loading dashboard data', style: TextStyle(color: AppTheme.red600))),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                      }

                      if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: Text('No loans found for your profile', style: TextStyle(color: AppTheme.gray500))),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final loanDoc = docs[index].data() as Map<String, dynamic>;
                          final lId = loanDoc['loanId']?.toString() ?? 'N/A';
                          final lAmountRaw = loanDoc['loanAmount'];
                          final lAmount = lAmountRaw is int ? lAmountRaw : int.tryParse(lAmountRaw?.toString() ?? '0') ?? 0;
                          final lPurpose = loanDoc['loanPurpose']?.toString() ?? 'N/A';
                          final lStatus = loanDoc['status']?.toString() ?? 'pending';
                          final lProgressRaw = loanDoc['progress'];
                          final lProgress = lProgressRaw is int ? lProgressRaw : int.tryParse(lProgressRaw?.toString() ?? '0') ?? 0;
                          final lDisbursed = _formatIsoDate(loanDoc['disbursedDate']?.toString());
                          final lDeadline = _formatIsoDate(loanDoc['deadline']?.toString());

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoanDetailsScreen(
                                    loanId: lId,
                                    name: beneficiaryName,
                                    amount: lAmount,
                                    status: lStatus,
                                    disbursedDate: lDisbursed,
                                    purpose: lPurpose,
                                    deadline: lDeadline,
                                    progress: lProgress,
                                  ),
                                ),
                              ),
                              child: _buildCard(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Loan Summary',
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('ID: $lId',
                                                style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.chevron_right, size: 16, color: AppTheme.gray400),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoItem(
                                            icon: Icons.currency_rupee,
                                            label: 'Loan Amount',
                                            value: '₹${_formatAmount(lAmount)}',
                                            valueSize: 20,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildInfoItem(
                                            icon: Icons.calendar_today,
                                            label: 'Deadline',
                                            value: lDeadline,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    _buildInfoItem(
                                      icon: Icons.gps_fixed,
                                      label: 'Purpose',
                                      value: lPurpose,
                                      fullWidth: true,
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB),
                                        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, color: AppTheme.amber600, size: 18),
                                              const SizedBox(width: 8),
                                              Text(lStatus == 'pending' ? 'Pending Verification' : 'Verified & Approved',
                                                  style: const TextStyle(color: AppTheme.amber600, fontSize: 12, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Utilization Progress',
                                                  style: TextStyle(fontSize: 11, color: AppTheme.gray600)),
                                              Text('$lProgress%',
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.gray600)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: lProgress / 100,
                                              minHeight: 6,
                                              backgroundColor: AppTheme.gray200,
                                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.blue500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // ── Pending Uploads Card ──────────────────────────────────────
                  if (_pendingCount > 0 || _uploadedCount > 0)
                    GestureDetector(
                      onTap: () async {
                        await Navigator.pushNamed(context, '/pending-uploads');
                        _loadCounts(); // Refresh counts on return
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _pendingCount > 0 ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _pendingCount > 0 ? Colors.orange.withOpacity(0.1) : AppTheme.green600.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _pendingCount > 0 ? Icons.cloud_upload : Icons.cloud_done,
                                color: _pendingCount > 0 ? Colors.orange : AppTheme.green600,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Upload Queue',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _pendingCount > 0
                                        ? '$_pendingCount pending · $_uploadedCount uploaded'
                                        : 'All $_uploadedCount uploads complete',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
                                  ),
                                ],
                              ),
                            ),
                            if (_pendingCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(12)),
                                child: Text('$_pendingCount',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: AppTheme.gray400),
                          ],
                        ),
                      ),
                    ),
                  if (_pendingCount > 0 || _uploadedCount > 0) const SizedBox(height: 16),

                  // GPS Camera Upload Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: AppTheme.green600.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/gps-camera-upload');
                        _loadCounts();
                      },
                      icon: const Icon(Icons.gps_fixed, color: Colors.white),
                      label: const Text('GPS Camera Upload', style: TextStyle(color: Colors.white)),
                      style: AppTheme.elevatedOnGradient(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Debug Button (temporary)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/upload-debug'),
                      icon: const Icon(Icons.bug_report, color: Colors.white),
                      label: const Text('Debug Upload', style: TextStyle(color: Colors.white)),
                      style: AppTheme.elevatedOnGradient(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // View History Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/history'),
                      icon: const Icon(Icons.history, color: Colors.white),
                      label: const Text('View Upload History',
                          style: TextStyle(color: Colors.white)),
                      style: AppTheme.elevatedOnGradient(),
                    ),
                  ),
                  const SizedBox(height: 16),



                  // Help Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.info_outline, color: AppTheme.blue600, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Need Help?',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                              const SizedBox(height: 16),
                              Text('Contact support for assistance with your loan application',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.gray600)),
                              const SizedBox(height: 16),
                              Row(
                                children: const [
                                  Text('Contact Support',
                                      style: TextStyle(fontSize: 11, color: AppTheme.blue600)),
                                  Icon(Icons.chevron_right, size: 14, color: AppTheme.blue600),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool fullWidth = false,
    double valueSize = 15,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.gray500),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
              const SizedBox(height: 16),
              Text(value,
                  style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              if (!isLast)
                Expanded(child: Container(width: 1, color: AppTheme.gray200, margin: const EdgeInsets.symmetric(vertical: 4))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.gray800)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatIsoDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final d = DateTime.parse(isoString);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (e) {
      return isoString;
    }
  }
}
