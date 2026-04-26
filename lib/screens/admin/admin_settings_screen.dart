import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import 'admin_broadcast_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.blue600),
            SizedBox(width: 8),
            Text('Security'),
          ],
        ),
        content: const Text('Admin access is secured with Firebase Authentication.\n\nMore advanced role permissions will be added here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showDataManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage_outlined, color: AppTheme.green600),
            SizedBox(width: 8),
            Text('Data Management'),
          ],
        ),
        content: const Text('Would you like to clear the local app cache? This will reset your notification read history and temporary data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.gray500))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red600),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local cache cleared successfully!'), backgroundColor: AppTheme.green600),
              );
            },
            child: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                colors: [Color(0xFF374151), Color(0xFF4B5563)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
                  label: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.settings, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Tools', style: TextStyle(color: Colors.grey[300], fontSize: 11)),
                        const Text('System Settings',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Settings items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingTile(
                  context,
                  title: 'Broadcast Notifications',
                  description: 'Send global alerts to all users',
                  icon: Icons.campaign_outlined,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBroadcastScreen())),
                ),
                const SizedBox(height: 16),
                _buildSettingTile(
                  context,
                  title: 'Security',
                  description: 'Access and permissions',
                  icon: Icons.shield_outlined,
                  onTap: () => _showSecurityDialog(context),
                ),
                const SizedBox(height: 16),
                _buildSettingTile(
                  context,
                  title: 'Data Management',
                  description: 'Clear local cache and sync status',
                  icon: Icons.storage_outlined,
                  onTap: () => _showDataManagementDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {required String title, required String description, required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.gray700),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.gray400),
        onTap: onTap,
      ),
    );
  }
}
