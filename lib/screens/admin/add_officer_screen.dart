import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';

class AddOfficerScreen extends StatefulWidget {
  const AddOfficerScreen({super.key});

  @override
  State<AddOfficerScreen> createState() => _AddOfficerScreenState();
}

class _AddOfficerScreenState extends State<AddOfficerScreen> {
  final _offNameCtrl = TextEditingController();
  final _offUsernameCtrl = TextEditingController();
  final _offPasswordCtrl = TextEditingController();
  String _offRole = 'field'; // 'field' or 'admin'

  bool _isSaving = false;

  @override
  void dispose() {
    _offNameCtrl.dispose();
    _offUsernameCtrl.dispose();
    _offPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _isOffValid =>
      _offNameCtrl.text.isNotEmpty &&
      _offUsernameCtrl.text.isNotEmpty &&
      _offPasswordCtrl.text.isNotEmpty;

  void _resetOffForm() {
    _offNameCtrl.clear();
    _offUsernameCtrl.clear();
    _offPasswordCtrl.clear();
    setState(() { _offRole = 'field'; });
  }

  Future<void> _saveOfficer() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('officers').add({
        'name': _offNameCtrl.text.trim(),
        'username': _offUsernameCtrl.text.trim(),
        'password': _offPasswordCtrl.text.trim(),
        'role': _offRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Officer Added Successfully!'), backgroundColor: Colors.green),
      );
      _resetOffForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
            decoration: const BoxDecoration(gradient: AppGradients.purpleHeader),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Add Officer', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(Icons.admin_panel_settings, 'Officer Authentication'),
                  const SizedBox(height: 16),
                  _field('Officer Name *', _offNameCtrl, 'Enter full name'),
                  _field('Username *', _offUsernameCtrl, 'Enter unique username (e.g. OFF001)'),
                  _field('Password *', _offPasswordCtrl, 'Enter password'),
                  const SizedBox(height: 16),
                  const Text('Role *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _offRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true, fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'field', child: Text('Field Officer (Upload Reviewer)')),
                      DropdownMenuItem(value: 'admin', child: Text('System Admin')),
                    ],
                    onChanged: (v) => setState(() => _offRole = v ?? 'field'),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSubmitButton('Save Officer', _isOffValid, _saveOfficer),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(String label, bool isValid, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: isValid ? AppTheme.purple600 : AppTheme.gray300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : TextButton(
              onPressed: isValid && !_isSaving ? onTap : null,
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.purple600),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.gray400),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
