import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import 'officer_details_screen.dart';

/// Displays a list of all officers. Each officer card is tappable to view details.
class ViewOfficersScreen extends StatefulWidget {
  const ViewOfficersScreen({super.key});

  @override
  State<ViewOfficersScreen> createState() => _ViewOfficersScreenState();
}

class _ViewOfficersScreenState extends State<ViewOfficersScreen> {
  List<Map<String, dynamic>> _officers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfficers();
  }

  Future<void> _fetchOfficers() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('officers')
          .where('role', isEqualTo: 'field')
          .get();
      
      final officersData = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      
      for (var officer in officersData) {
        final username = officer['username'] as String?;
        if (username != null) {
          final benSnap = await FirebaseFirestore.instance
              .collection('beneficiaries')
              .where('assignedOfficer', isEqualTo: username)
              .get();
          officer['assignedCount'] = benSnap.size;
        } else {
          officer['assignedCount'] = 0;
        }
      }

      if (mounted) {
        setState(() {
          _officers = officersData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.groups, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('All Officers', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        Text('${_officers.length} officers registered', style: TextStyle(color: Colors.purple[100], fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _officers.isEmpty
                    ? const Center(child: Text('No officers found.', style: TextStyle(color: AppTheme.gray500)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _officers.length,
                        itemBuilder: (context, index) {
                          final o = _officers[index];
                          final assignedCount = o['assignedCount'] ?? 0;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OfficerDetailsScreen(officer: o)),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.manage_accounts, size: 28, color: Color(0xFF7C3AED)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(o['name'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
                                        const SizedBox(height: 2),
                                        Text(o['username'] as String? ?? 'N/A', style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.people_outline, size: 14, color: AppTheme.gray400),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$assignedCount beneficiaries assigned',
                                              style: const TextStyle(fontSize: 12, color: AppTheme.gray600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$assignedCount',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: AppTheme.gray400),
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
