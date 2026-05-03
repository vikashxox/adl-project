import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import 'admin_profile_screen.dart';
import 'view_officers_screen.dart';
import 'view_beneficiaries_screen.dart';
import 'admin_uploads_screen.dart';
import 'add_officer_screen.dart';
import 'add_extra_loan_screen.dart';
import 'admin_broadcast_screen.dart';
import '../../widgets/notification_bell.dart';
import '../../services/app_session.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      {'title': 'View all uploads', 'desc': 'See every submission (read-only)', 'icon': Icons.cloud_upload, 'gradient': const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]), 'screen': const AdminUploadsScreen(allowReviewActions: false)},
      {'title': 'Add Beneficiary', 'desc': 'Create new loan record', 'icon': Icons.person_add, 'gradient': AppGradients.purpleHeader, 'route': '/admin-data-entry'},
      {'title': 'Assign Extra Loan', 'desc': 'Add loan to existing beneficiary', 'icon': Icons.post_add, 'gradient': const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]), 'screen': const AddExtraLoanScreen()},
      {'title': 'Add Officer', 'desc': 'Create new officer record', 'icon': Icons.admin_panel_settings, 'gradient': AppGradients.blueHeader, 'screen': const AddOfficerScreen()},
      {'title': 'Send Broadcast', 'desc': 'Global app notifications', 'icon': Icons.campaign, 'gradient': const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]), 'screen': const AdminBroadcastScreen()},
      {'title': 'Export Report', 'desc': 'Download analytics reports', 'icon': Icons.bar_chart, 'gradient': AppGradients.greenHeader, 'route': '/admin-export-report'},
      {'title': 'System Settings', 'desc': 'Configure system', 'icon': Icons.settings, 'gradient': AppGradients.grayHeader, 'route': '/admin-settings'},
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.gray50,
        body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.verified_user, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome', style: TextStyle(color: Colors.purple[100], fontSize: 11)),
                      const Text('Admin Dashboard',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const NotificationBell(),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.account_circle, size: 24, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Stats Grid
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('beneficiaries').snapshots(),
                    builder: (context, snapshot) {
                      int totalBeneficiaries = 0;
                      int totalLoans = 0;
                      int pending = 0;
                      int approved = 0;

                      if (snapshot.hasData) {
                        final docs = snapshot.data!.docs;
                        totalLoans = docs.length;
                        final uniquePhones = <String>{};
                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final phone = data['phone']?.toString() ?? '';
                          if (phone.isNotEmpty) uniquePhones.add(phone);
                          final status = data['status']?.toString() ?? 'pending';
                          if (status == 'pending') pending++;
                          if (status == 'approved') approved++;
                        }
                        totalBeneficiaries = uniquePhones.length;
                      }

                      final statsList = [
                        {'label': 'Total Beneficiaries', 'value': '$totalBeneficiaries', 'icon': Icons.group, 'color': AppTheme.blue600, 'bg': const Color(0xFFEFF6FF)},
                        {'label': 'Total Loans', 'value': '$totalLoans', 'icon': Icons.trending_up, 'color': AppTheme.green600, 'bg': const Color(0xFFF0FDF4)},
                        {'label': 'Pending', 'value': '$pending', 'icon': Icons.access_time, 'color': AppTheme.amber600, 'bg': const Color(0xFFFFFBEB)},
                        {'label': 'Approved', 'value': '$approved', 'icon': Icons.check_circle, 'color': AppTheme.green600, 'bg': const Color(0xFFF0FDF4)},
                      ];

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: statsList.map((s) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: s['bg'] as Color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(s['icon'] as IconData, size: 18, color: s['color'] as Color),
                              ),
                              const Spacer(),
                              Text(s['value'] as String,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.gray800)),
                              Text(s['label'] as String,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                            ],
                          ),
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // View Officers / View Beneficiaries
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewOfficersScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: AppTheme.green600.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.groups, size: 32, color: Colors.white),
                                SizedBox(height: 8),
                                Text('View Officers', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('Manage & review', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewBeneficiariesScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: AppTheme.blue600.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.group, size: 32, color: Colors.white),
                                SizedBox(height: 8),
                                Text('View Beneficiaries', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('All loan records', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text('Quick Actions',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                  const SizedBox(height: 16),
                  ...quickActions.map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        if (action.containsKey('screen')) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => action['screen'] as Widget));
                        } else {
                          Navigator.pushNamed(context, action['route'] as String);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: action['gradient'] as LinearGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(action['icon'] as IconData, size: 24, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(action['title'] as String,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                                  Text(action['desc'] as String,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppTheme.gray400),
                          ],
                        ),
                      ),
                    ),
                  )).toList(),
                  const SizedBox(height: 16),

                  // System Overview
                  const Text('System Overview',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('officers').snapshots(),
                    builder: (context, snapshot) {
                      int activeOfficers = 0;
                      if (snapshot.hasData) {
                        activeOfficers = snapshot.data!.docs.length;
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFAF5FF), Color(0xFFEFF6FF)],
                          ),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _overviewRow('Active Officers', '$activeOfficers'),
                            const Divider(height: 16),
                            _overviewRow('Districts Covered', '12'),
                            const Divider(height: 16),
                            _overviewRow('System Status', 'Online', valueColor: AppTheme.green600),
                          ],
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 16),

                  // Logout
                  OutlinedButton(
                    onPressed: () {
                      AppSession.clear();
                      Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (_) => false);
                    },
                    style: AppTheme.outlinedFullWidth(),
                    child: const Text('Logout'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _overviewRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.gray700)),
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? AppTheme.gray800)),
      ],
    );
  }
}

