import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_profile_screen.dart';
import 'view_officers_screen.dart';
import 'view_beneficiaries_screen.dart';
import 'admin_uploads_screen.dart';
import 'add_officer_screen.dart';
import 'add_extra_loan_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _statsData;
  List<dynamic> _activityData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await ApiService.getDashboardStats();
      final activity = await ApiService.getDashboardActivity();
      if (mounted) setState(() { _statsData = stats; _activityData = activity; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'label': 'Total Beneficiaries', 'value': '${_statsData?['totalBeneficiaries'] ?? 0}', 'icon': Icons.group, 'color': AppTheme.blue600, 'bg': const Color(0xFFEFF6FF)},
      {'label': 'Total Loans', 'value': _statsData?['totalLoans'] ?? '₹0', 'icon': Icons.trending_up, 'color': AppTheme.green600, 'bg': const Color(0xFFF0FDF4)},
      {'label': 'Pending', 'value': '${_statsData?['pending'] ?? 0}', 'icon': Icons.access_time, 'color': AppTheme.amber600, 'bg': const Color(0xFFFFFBEB)},
      {'label': 'Approved', 'value': '${_statsData?['approved'] ?? 0}', 'icon': Icons.check_circle, 'color': AppTheme.green600, 'bg': const Color(0xFFF0FDF4)},
    ];

    final quickActions = [
      {'title': 'View all uploads', 'desc': 'See every submission (read-only)', 'icon': Icons.cloud_upload, 'gradient': const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]), 'screen': const AdminUploadsScreen(allowReviewActions: false)},
      {'title': 'Add Beneficiary', 'desc': 'Create new loan record', 'icon': Icons.person_add, 'gradient': AppGradients.purpleHeader, 'route': '/admin-data-entry'},
      {'title': 'Assign Extra Loan', 'desc': 'Add loan to existing beneficiary', 'icon': Icons.post_add, 'gradient': const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]), 'screen': const AddExtraLoanScreen()},
      {'title': 'Add Officer', 'desc': 'Create new officer record', 'icon': Icons.admin_panel_settings, 'gradient': AppGradients.blueHeader, 'screen': const AddOfficerScreen()},
      {'title': 'Export Report', 'desc': 'Download analytics reports', 'icon': Icons.bar_chart, 'gradient': AppGradients.greenHeader, 'route': '/admin-export-report'},
      {'title': 'System Settings', 'desc': 'Configure system', 'icon': Icons.settings, 'gradient': AppGradients.grayHeader, 'route': '/admin-settings'},
    ];


    final List<Map<String, dynamic>> fallbackActivity = [];

    final activity = _activityData.isNotEmpty ? _activityData : fallbackActivity;

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
                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: stats.map((s) => Container(
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
                  )),
                  const SizedBox(height: 16),

                  // Recent Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Activity',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF9333EA))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: Column(
                      children: activity.map<Widget>((a) {
                        final isLast = a == activity.last;
                        return Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.info_outline, size: 16, color: Color(0xFF9333EA)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a['text'] as String,
                                          style: const TextStyle(fontSize: 13, color: AppTheme.gray800)),
                                      Text(a['time'] as String,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast) const Divider(height: 16),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // System Overview
                  const Text('System Overview',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                  const SizedBox(height: 16),
                  Container(
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
                        _overviewRow('Active Officers', '0'),
                        const Divider(height: 16),
                        _overviewRow('Districts Covered', '0'),
                        const Divider(height: 16),
                        _overviewRow('Success Rate', '0%', valueColor: AppTheme.green600),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (_) => false),
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
    );
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
