import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _targetRole = 'all'; // all, officer, beneficiary
  bool _isSending = false;

  Future<void> _sendBroadcast() async {
    final title = _titleCtrl.text.trim();
    final msg = _msgCtrl.text.trim();

    if (title.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and message.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'message': msg,
        'targetRole': _targetRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent successfully!'), backgroundColor: AppTheme.green600),
      );
      
      _titleCtrl.clear();
      _msgCtrl.clear();
      setState(() => _targetRole = 'all');
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppTheme.red600),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFEF4444)], // Red header for alert/broadcast
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('Send Broadcast', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: AppTheme.red600, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Global Notification', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.red600)),
                        Text('Send an instant popup alert to specific users or everyone.', style: TextStyle(fontSize: 12, color: AppTheme.red600)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Target Audience *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _targetRole,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'officer', child: Text('Field Officers Only')),
                    DropdownMenuItem(value: 'beneficiary', child: Text('Beneficiaries Only')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _targetRole = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Title *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. System Maintenance',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.gray200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.gray200)),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Message *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
            const SizedBox(height: 8),
            TextField(
              controller: _msgCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your notification message here...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.gray200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.gray200)),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendBroadcast,
                icon: _isSending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.white),
                label: Text(_isSending ? 'Sending...' : 'Send Broadcast', style: const TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
