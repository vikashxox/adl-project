import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../utils/app_theme.dart';
import '../../services/app_session.dart';
import '../../widgets/notification_bell.dart';
import 'officer_profile_screen.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  String _activeFilter = 'pending';
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _verifications = [];
  List<String> _assignedPhones = [];
  StreamSubscription<QuerySnapshot>? _uploadsSub;
  StreamSubscription<QuerySnapshot>? _beneficiariesSub;

  @override
  void initState() {
    super.initState();
    _loadAssignedData();
  }

  void _loadAssignedData() {
    final officerId = AppSession.officerId;
    if (officerId == null) return;

    _beneficiariesSub = FirebaseFirestore.instance
        .collection('beneficiaries')
        .where('assignedOfficer', isEqualTo: officerId)
        .snapshots()
        .listen((bSnap) {
      if (!mounted) return;
      _assignedPhones = bSnap.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['phone'] as String?)
          .where((phone) => phone != null && phone.isNotEmpty)
          .cast<String>()
          .toList();

      _setupUploadsSub();
    });
  }

  void _setupUploadsSub() {
    _uploadsSub?.cancel();
    _uploadsSub = FirebaseFirestore.instance
        .collection('uploads')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _verifications.clear();
        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final phone = data['phone']?.toString() ?? '';
          if (_assignedPhones.contains(phone)) {
            _verifications.add({
              'id': doc.id,
              'name': 'User: $phone', // Fallback since name isn't in uploads
              'phone': phone,
              'loanId': data['loanId'] ?? 'N/A',
              'amount': 0, // Placeholder
              'date': _formatIsoDate(data['timestamp']?.toString()),
              'purpose': 'Proof Upload',
              'status': data['status'] ?? 'pending',
              'aiConfidence': 85, // Dummy AI confidence
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _beneficiariesSub?.cancel();
    _uploadsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _formatIsoDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final d = DateTime.parse(isoString);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (e) {
      return isoString;
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _verifications.where((v) {
      final matchesFilter = _activeFilter == 'all' || v['status'] == _activeFilter;
      final q = _searchController.text.toLowerCase();
      final matchesSearch = q.isEmpty ||
          (v['name'] as String).toLowerCase().contains(q) ||
          (v['loanId'] as String).toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  int _count(String status) => _verifications.where((v) => v['status'] == status).length;

  Color _aiColor(int confidence) {
    if (confidence >= 80) return AppTheme.green600;
    if (confidence >= 60) return AppTheme.amber600;
    return AppTheme.red600;
  }

  Color _aiBg(int confidence) {
    if (confidence >= 80) return const Color(0xFFF0FDF4);
    if (confidence >= 60) return const Color(0xFFFFFBEB);
    return const Color(0xFFFEF2F2);
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'pending': return {'icon': Icons.access_time, 'color': AppTheme.amber600, 'bg': const Color(0xFFFFFBEB), 'text': 'Pending'};
      case 'flagged': return {'icon': Icons.warning_amber_rounded, 'color': AppTheme.red600, 'bg': const Color(0xFFFEF2F2), 'text': 'Flagged'};
      case 'approved': return {'icon': Icons.check_circle, 'color': AppTheme.green600, 'bg': const Color(0xFFF0FDF4), 'text': 'Approved'};
      default: return {'icon': Icons.circle, 'color': AppTheme.gray500, 'bg': AppTheme.gray50, 'text': 'Unknown'};
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
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.manage_accounts, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome', style: TextStyle(color: Colors.green[100], fontSize: 11)),
                          const Text('Officer Dashboard',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const NotificationBell(),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerProfileScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.account_circle, size: 24, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
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
              ],
            ),
          ),

          // Live Firestore queue — officer can approve/reject
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 0,
              shadowColor: Colors.black26,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/officer-uploads'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fact_check, color: AppTheme.green600, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Review upload queue',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.gray800)),
                            SizedBox(height: 2),
                            Text('Approve or reject beneficiary proofs (Firestore)',
                                style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.gray400),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _StatChip(count: _count('pending'), label: 'Pending', color: AppTheme.amber600)),
                const SizedBox(width: 8),
                Expanded(child: _StatChip(count: _count('flagged'), label: 'Flagged', color: AppTheme.red600)),
                const SizedBox(width: 8),
                Expanded(child: _StatChip(count: _count('approved'), label: 'Approved', color: AppTheme.green600)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Icon(Icons.filter_list, size: 18, color: AppTheme.gray600),
                const SizedBox(width: 8),
                for (final filter in ['all', 'pending', 'flagged', 'approved'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeFilter == filter ? AppTheme.green600 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _activeFilter == filter ? AppTheme.green600 : AppTheme.gray200),
                        ),
                        child: Text(
                          filter[0].toUpperCase() + filter.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: _activeFilter == filter ? Colors.white : AppTheme.gray600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No verifications found', style: TextStyle(color: AppTheme.gray500)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final v = _filtered[index];
                      final sc = _statusConfig(v['status'] as String);
                      final confidence = v['aiConfidence'] as int;
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/verification-detail/${v['id']}'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v['name'] as String,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                                        Text('ID: ${v['loanId']}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: sc['bg'] as Color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(sc['icon'] as IconData, size: 12, color: sc['color'] as Color),
                                        const SizedBox(width: 4),
                                        Text(sc['text'] as String,
                                            style: TextStyle(fontSize: 11, color: sc['color'] as Color)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _DetailItem(
                                      icon: Icons.currency_rupee,
                                      label: 'Amount',
                                      value: '₹${(v['amount'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _DetailItem(
                                      icon: Icons.calendar_today,
                                      label: 'Submitted',
                                      value: v['date'] as String,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Purpose', style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                              Text(v['purpose'] as String,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.gray800)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.bolt, size: 16, color: Color(0xFF9333EA)),
                                  const SizedBox(width: 4),
                                  const Text('AI Confidence', style: TextStyle(fontSize: 11, color: AppTheme.gray600)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _aiBg(confidence),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _aiColor(confidence).withOpacity(0.3)),
                                    ),
                                    child: Text('$confidence%',
                                        style: TextStyle(fontSize: 11, color: _aiColor(confidence), fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text('View Details',
                                      style: TextStyle(fontSize: 11, color: AppTheme.green600)),
                                  const Icon(Icons.chevron_right, size: 16, color: AppTheme.green600),
                                ],
                              ),
                            ],
                          ),
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

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray600)),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.gray400),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.gray500)),
            Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.gray800)),
          ],
        ),
      ],
    );
  }
}
