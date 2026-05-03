import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/app_session.dart';

/// Admin profile screen — shows admin info, role, and system privileges.
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final officerId = AppSession.officerId;
    if (officerId == null || officerId == 'admin') {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('officers')
          .where('username', isEqualTo: officerId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        _profile = snap.docs.first.data();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppTheme.gray50, body: Center(child: CircularProgressIndicator()));
    }

    final name = _profile?['name'] ?? 'System Admin';
    final id = _profile?['username'] ?? AppSession.officerId ?? 'admin';
    final role = 'System Administrator';
    final email = _profile?['email'] ?? 'admin@loandept.gov.in';
    final phone = _profile?['phone'] ?? 'N/A';
    final department = _profile?['department'] ?? 'Rural Development & Panchayati Raj';

    final privileges = [
      {'icon': Icons.group_add, 'label': 'Manage Beneficiaries', 'desc': 'Add, edit, and remove beneficiary records'},
      {'icon': Icons.manage_accounts, 'label': 'Manage Officers', 'desc': 'Assign and reassign field officers'},
      {'icon': Icons.bar_chart, 'label': 'Reports & Analytics', 'desc': 'Generate and export system reports'},
      {'icon': Icons.settings, 'label': 'System Configuration', 'desc': 'Configure system settings and parameters'},
      {'icon': Icons.security, 'label': 'Audit Logs', 'desc': 'View all system activity and audit trails'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
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
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.admin_panel_settings, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(role, style: TextStyle(color: Colors.purple[100], fontSize: 14)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Info Card
                  _buildCard(
                    title: 'Admin Details',
                    children: [
                      _buildInfoTile(Icons.badge, 'Admin ID', id),
                      _buildInfoTile(Icons.work_outline, 'Role', role),
                      _buildInfoTile(Icons.phone, 'Phone', phone),
                      _buildInfoTile(Icons.email_outlined, 'Email', email),
                      _buildInfoTile(Icons.apartment, 'Department', department),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Privileges
                  Container(
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
                        const Text('System Privileges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray800)),
                        const SizedBox(height: 16),
                        ...privileges.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(p['icon'] as IconData, size: 20, color: const Color(0xFF7C3AED)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['label'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
                                    Text(p['desc'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle, size: 18, color: AppTheme.green600),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
            decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
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
