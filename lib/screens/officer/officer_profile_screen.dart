import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/app_session.dart';

/// Officer profile screen — shows officer info, role, and contact details.
class OfficerProfileScreen extends StatefulWidget {
  const OfficerProfileScreen({super.key});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  Map<String, dynamic>? _profile;
  String? _docId;
  int _assignedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final officerId = AppSession.officerId;
    if (officerId == null) {
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
        _docId = snap.docs.first.id;
        _profile = snap.docs.first.data();
      }

      final bs = await FirebaseFirestore.instance
          .collection('beneficiaries')
          .where('assignedOfficer', isEqualTo: officerId)
          .get();
      _assignedCount = bs.docs.length;
    } catch (_) {}
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppTheme.gray50, body: Center(child: CircularProgressIndicator()));
    }

    final name = _profile?['name'] ?? 'Unknown Officer';
    final id = _profile?['username'] ?? AppSession.officerId ?? 'N/A';
    final role = _profile?['role'] == 'admin' ? 'System Administrator' : 'Field Verification Officer';
    final phone = _profile?['phone'] ?? 'N/A';
    final email = _profile?['email'] ?? 'N/A';
    final district = _profile?['district'] ?? 'N/A';
    final assignedCases = _assignedCount.toString();
    final completedCases = '0';

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
                    child: const Icon(Icons.manage_accounts, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(role, style: TextStyle(color: Colors.green[100], fontSize: 14)),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCard(
                    title: 'Officer Details',
                    iconBg: const Color(0xFFF0FDF4),
                    iconColor: AppTheme.green600,
                    children: [
                      _buildInfoTile(Icons.badge, 'Officer ID', id),
                      _buildInfoTile(Icons.work_outline, 'Role', role),
                      _buildInfoTile(Icons.phone, 'Phone', phone),
                      _buildInfoTile(Icons.email_outlined, 'Email', email),
                      _buildInfoTile(Icons.location_city, 'District', district),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _statCard('Active Cases', assignedCases, AppTheme.amber600, const Color(0xFFFFFBEB)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard('Completed', completedCases, AppTheme.green600, const Color(0xFFF0FDF4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  OutlinedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Change Password'),
                    style: AppTheme.outlinedFullWidth(sideColor: AppTheme.green600, foregroundColor: AppTheme.green600),
                  ),
                  const SizedBox(height: 16),

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

  Widget _statCard(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
        ],
      ),
    );
  }

  Widget _buildCard({
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

  Widget _buildInfoTile(IconData icon, String label, String value) {
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

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
                  const SizedBox(height: 8),
                  TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
                  const SizedBox(height: 8),
                  TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.gray500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green600),
                onPressed: isSaving ? null : () async {
                  final current = currentCtrl.text.trim();
                  final newPass = newCtrl.text.trim();
                  final confirm = confirmCtrl.text.trim();

                  if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                    return;
                  }
                  if (current != _profile?['password']) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current password is incorrect')));
                    return;
                  }
                  if (newPass != confirm) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
                    return;
                  }
                  if (_docId == null) return;

                  setDialogState(() => isSaving = true);
                  try {
                    await FirebaseFirestore.instance.collection('officers').doc(_docId).update({'password': newPass});
                    _profile!['password'] = newPass; // update local memory
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!'), backgroundColor: AppTheme.green600));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    if (ctx.mounted) setDialogState(() => isSaving = false);
                  }
                },
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Change Password', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }
}
