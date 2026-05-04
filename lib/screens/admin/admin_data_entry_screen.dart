import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';

class AdminDataEntryScreen extends StatefulWidget {
  const AdminDataEntryScreen({super.key});

  @override
  State<AdminDataEntryScreen> createState() => _AdminDataEntryScreenState();
}

class _AdminDataEntryScreenState extends State<AdminDataEntryScreen> {
  List<Map<String, dynamic>> _officers = [];
  bool _isLoadingOfficers = true;

  @override
  void initState() {
    super.initState();
    _fetchOfficers();
  }

  Future<void> _fetchOfficers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('officers').where('role', isEqualTo: 'field').get();
      if (mounted) {
        setState(() {
          _officers = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _isLoadingOfficers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOfficers = false);
    }
  }

  // --- BENEFICIARY FIELDS ---
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _landLocationCtrl = TextEditingController();
  final _landAreaCtrl = TextEditingController();
  final _loanAmountCtrl = TextEditingController();
  String _loanPurpose = '';
  String _assignedOfficer = '';
  DateTime? _disbursementDate;
  DateTime? _deadline;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _mobileCtrl.dispose(); _addressCtrl.dispose();
    _villageCtrl.dispose(); _districtCtrl.dispose(); _stateCtrl.dispose();
    _pincodeCtrl.dispose(); _landLocationCtrl.dispose(); _landAreaCtrl.dispose();
    _loanAmountCtrl.dispose();
    super.dispose();
  }

  bool get _isBenValid =>
      _nameCtrl.text.isNotEmpty &&
      _mobileCtrl.text.length == 10 &&
      _addressCtrl.text.isNotEmpty &&
      _landLocationCtrl.text.isNotEmpty &&
      _landAreaCtrl.text.isNotEmpty &&
      _loanAmountCtrl.text.isNotEmpty &&
      _loanPurpose.isNotEmpty &&
      _assignedOfficer.isNotEmpty &&
      _disbursementDate != null &&
      _deadline != null;

  void _resetBenForm() {
    _nameCtrl.clear(); _mobileCtrl.clear(); _addressCtrl.clear();
    _villageCtrl.clear(); _districtCtrl.clear(); _stateCtrl.clear();
    _pincodeCtrl.clear(); _landLocationCtrl.clear(); _landAreaCtrl.clear();
    _loanAmountCtrl.clear();
    setState(() { _loanPurpose = ''; _assignedOfficer = ''; _disbursementDate = null; _deadline = null; });
  }

  Future<void> _saveBeneficiary() async {
    setState(() => _isSaving = true);
    try {
      final loanId = 'LN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      await FirebaseFirestore.instance.collection('beneficiaries').add({
        'name': _nameCtrl.text.trim(),
        'phone': _mobileCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'landLocation': _landLocationCtrl.text.trim(),
        'landArea': _landAreaCtrl.text.trim(),
        'loanAmount': int.tryParse(_loanAmountCtrl.text) ?? 0,
        'loanPurpose': _loanPurpose,
        'assignedOfficerId': _assignedOfficer,
        'assignedOfficerName': _officers.firstWhere((o) => o['id'] == _assignedOfficer)['name'],
        'disbursedDate': _disbursementDate!.toIso8601String(),
        'deadline': _deadline!.toIso8601String(),
        'loanId': loanId,
        'status': 'pending',
        'progress': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beneficiary Added Successfully!'), backgroundColor: Colors.green),
      );
      _resetBenForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate(bool isDisbursement) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isDisbursement) _disbursementDate = picked;
        else _deadline = picked;
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
                const Text('Add Beneficiary', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Form
          Expanded(
            child: _buildBeneficiaryForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.person_add, 'Beneficiary Information'),
          const SizedBox(height: 16),
          _field('Full Name *', _nameCtrl, 'Enter beneficiary full name'),
          _field('Mobile Number *', _mobileCtrl, '10-digit mobile number',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
          _field('Address *', _addressCtrl, 'Enter address'),
          _field('Village', _villageCtrl, 'Enter village'),
          _field('District', _districtCtrl, 'Enter district'),
          _field('State', _stateCtrl, 'Enter state'),
          _field('Pincode', _pincodeCtrl, '6-digit pincode',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
          _field('Land Location *', _landLocationCtrl, 'Enter land location'),
          _field('Land Area (sq ft) *', _landAreaCtrl, 'Enter land area',
              keyboardType: TextInputType.number),

          const Divider(height: 32),
          _sectionHeader(Icons.currency_rupee, 'Loan Details'),
          const SizedBox(height: 16),
          _field('Loan Amount (₹) *', _loanAmountCtrl, 'Enter loan amount',
              keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          const Text('Loan Purpose *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _loanPurpose.isEmpty ? null : _loanPurpose,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true, fillColor: Colors.white,
            ),
            hint: const Text('Select purpose'),
            items: ['Agricultural Equipment', 'Dairy Equipment', 'Farm Machinery', 'Other']
                .map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _loanPurpose = v ?? ''),
          ),
          const SizedBox(height: 16),
          const Text('Assign Officer *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
          const SizedBox(height: 8),
          _isLoadingOfficers
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  value: _assignedOfficer.isEmpty ? null : _assignedOfficer,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true, fillColor: Colors.white,
                  ),
                  hint: const Text('Select field officer'),
                  items: _officers.map((o) => DropdownMenuItem(value: o['id'] as String, child: Text(o['name'] as String))).toList(),
                  onChanged: (v) => setState(() => _assignedOfficer = v ?? ''),
                ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _datePicker('Disbursement Date *', _disbursementDate, () => _pickDate(true))),
              const SizedBox(width: 12),
              Expanded(child: _datePicker('Deadline *', _deadline, () => _pickDate(false))),
            ],
          ),

          const SizedBox(height: 32),
          _buildSubmitButton('Save Beneficiary', _isBenValid, _saveBeneficiary),
          const SizedBox(height: 24),
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

  // UI Helpers
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.purple600),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
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

  Widget _datePicker(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.gray400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppTheme.gray500),
                const SizedBox(width: 6),
                Text(
                  _formatDate(date),
                  style: TextStyle(fontSize: 12, color: date == null ? AppTheme.gray500 : AppTheme.gray800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
