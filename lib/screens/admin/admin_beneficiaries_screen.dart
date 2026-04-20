import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class AdminBeneficiariesScreen extends StatefulWidget {
  const AdminBeneficiariesScreen({super.key});

  @override
  State<AdminBeneficiariesScreen> createState() => _AdminBeneficiariesScreenState();
}

class _AdminBeneficiariesScreenState extends State<AdminBeneficiariesScreen> {
  List<dynamic> _beneficiaries = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  final List<dynamic> _fallback = [];
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    try {
      final data = await ApiService.getBeneficiaries();
      if (mounted) setState(() { _beneficiaries = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _rows {
    final source = _beneficiaries.isNotEmpty ? _beneficiaries : _fallback;
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return source;
    return source.where((b) =>
        (b['name'] as String).toLowerCase().contains(q) ||
        (b['id'] as String).toLowerCase().contains(q)).toList();
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
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
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
                      child: const Icon(Icons.group, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Tools', style: TextStyle(color: Colors.blue[100], fontSize: 11)),
                        const Text('All Beneficiaries',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or loan ID...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.gray400),
                prefixIcon: const Icon(Icons.search, color: AppTheme.gray400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.blue600))
                : _rows.isEmpty
                    ? const Center(child: Text('No beneficiaries found', style: TextStyle(color: AppTheme.gray500)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = _rows[index];
                          final isApproved = item['status'] == 'Approved';
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['name'] as String,
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                                          Text('Loan ID: ${item['id']}',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                                        ],
                                      ),
                                    ),
                                    Text(item['amount'] as String,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      isApproved ? Icons.check_circle : Icons.access_time,
                                      size: 16,
                                      color: isApproved ? AppTheme.green600 : AppTheme.amber600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item['status'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isApproved ? AppTheme.green600 : AppTheme.amber600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
