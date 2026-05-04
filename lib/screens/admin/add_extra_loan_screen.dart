import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';

class AddExtraLoanScreen extends StatefulWidget {
  const AddExtraLoanScreen({super.key});

  @override
  State<AddExtraLoanScreen> createState() => _AddExtraLoanScreenState();
}

class _AddExtraLoanScreenState extends State<AddExtraLoanScreen> {
  final _searchPhoneCtrl = TextEditingController();
  
  bool _isSearching = false;
  Map<String, dynamic>? _existingProfile;
  
  // Extra Loan Fields
  final _loanAmountCtrl = TextEditingController();
  String _loanPurpose = '';
  String _assignedOfficer = '';
  DateTime? _disbursementDate;
  DateTime? _deadline;
  
  List<Map<String, dynamic>> _officers = [];
  bool _isLoadingOfficers = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchOfficers();
  }

  @override
  void dispose() {
    _searchPhoneCtrl.dispose();
    _loanAmountCtrl.dispose();
    super.dispose();
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

  Future<void> _searchBeneficiary() async {
    final phone = _searchPhoneCtrl.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit phone number.')));
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final snap = await FirebaseFirestore.instance
          .collection('beneficiaries')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (!mounted) return;
      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No beneficiary found with this number.')));
        setState(() => _existingProfile = null);
      } else {
        setState(() => _existingProfile = snap.docs.first.data());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  bool get _isFormValid =>
      _loanAmountCtrl.text.isNotEmpty &&
      _loanPurpose.isNotEmpty &&
      _assignedOfficer.isNotEmpty &&
      _disbursementDate != null &&
      _deadline != null &&
      _existingProfile != null;

  Future<void> _saveExtraLoan() async {
    if (_existingProfile == null) return;
    setState(() => _isSaving = true);
    
    try {
      final loanId = 'LN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      
      // Merge existing profile fields with new loan details
      final newDoc = {
        'name': _existingProfile!['name'] ?? '',
        'phone': _existingProfile!['phone'] ?? '',
        'address': _existingProfile!['address'] ?? '',
        'village': _existingProfile!['village'],
        'district': _existingProfile!['district'],
        'state': _existingProfile!['state'],
        'pincode': _existingProfile!['pincode'],
        'landLocation': _existingProfile!['landLocation'],
        'landArea': _existingProfile!['landArea'],
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
      };

      await FirebaseFirestore.instance.collection('beneficiaries').add(newDoc);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Extra Loan Assigned Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: const BoxDecoration(gradient: AppGradients.blueHeader),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('Assign Extra Loan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Box
            const Text('Search Existing Beneficiary *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    decoration: InputDecoration(
                      hintText: 'Enter 10-digit mobile number',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.gray400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true, fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, color: AppTheme.gray400),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _isSearching ? null : _searchBeneficiary,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.blue600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: _isSearching
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_existingProfile != null) ...[
              // Profile Found Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.blue600, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_existingProfile!['name'] ?? 'Unknown Name', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.gray800)),
                          Text('Phone: ${_existingProfile!['phone'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: AppTheme.gray600)),
                          Text('Address: ${_existingProfile!['address'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: AppTheme.gray600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),

              // Loan Form
              Row(
                children: const [
                  Icon(Icons.currency_rupee, size: 20, color: AppTheme.blue600),
                  SizedBox(width: 8),
                  Text('New Loan Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
                ],
              ),
              const SizedBox(height: 16),

              _field('Loan Amount (₹) *', _loanAmountCtrl, 'Enter loan amount', keyboardType: TextInputType.number),
              
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

              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: _isFormValid ? AppTheme.blue600 : AppTheme.gray300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isSaving
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : TextButton(
                        onPressed: _isFormValid && !_isSaving ? _saveExtraLoan : null,
                        child: const Text('Assign Sub-Loan', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {TextInputType? keyboardType}) {
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
