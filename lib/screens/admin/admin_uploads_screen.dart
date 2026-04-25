import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/firestore_image_url.dart';
import '../../utils/firestore_query_helpers.dart';
import '../../services/app_session.dart';
import '../../services/upload_history_query.dart';
import '../../services/upload_review_service.dart';
import '../../widgets/upload_review_actions.dart';

/// Lists beneficiary uploads from Firestore.
///
/// * **Admin** ([allowReviewActions] == false): read-only — no approve/reject.
/// * **Officer** ([allowReviewActions] == true): may approve/reject pending items
///   (also enforced by [UploadReviewService] + [AppSession]).
class AdminUploadsScreen extends StatefulWidget {
  /// When `true`, shows Approve/Reject for pending rows **only if** the user is a logged-in field officer.
  final bool allowReviewActions;

  const AdminUploadsScreen({super.key, this.allowReviewActions = false});

  @override
  State<AdminUploadsScreen> createState() => _AdminUploadsScreenState();
}

class _AdminUploadsScreenState extends State<AdminUploadsScreen> {
  String _statusFilter = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _busyDocId;

  List<String>? _assignedPhones;
  StreamSubscription<QuerySnapshot>? _beneficiariesSub;

  @override
  void initState() {
    super.initState();
    if (widget.allowReviewActions && AppSession.role == AppRole.officer && AppSession.officerId != null) {
      _beneficiariesSub = FirebaseFirestore.instance
          .collection('beneficiaries')
          .where('assignedOfficer', isEqualTo: AppSession.officerId)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() {
          _assignedPhones = snap.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['phone'] as String?)
              .where((phone) => phone != null && phone.isNotEmpty)
              .cast<String>()
              .toList();
        });
      });
    }
  }

  @override
  void dispose() {
    _beneficiariesSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Uses [UploadHistoryQuery.uploadsQueryForStaff] — `where` before `orderBy` when filtering.
  Query<Map<String, dynamic>> get _staffQuery =>
      UploadHistoryQuery.uploadsQueryForStaff(statusFilter: _statusFilter);

  Future<void> _onReviewTap(String docId, String newStatus) async {
    if (!widget.allowReviewActions || !AppSession.canReviewUploads) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only field officers can approve or reject uploads.')),
      );
      return;
    }
    setState(() => _busyDocId = docId);
    try {
      await UploadReviewService.instance.updateUploadReviewStatus(
        docId: docId,
        status: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as $newStatus'),
            backgroundColor: newStatus == 'approved' ? AppTheme.green600 : AppTheme.red600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: AppTheme.red600),
        );
      }
    } finally {
      if (mounted) setState(() => _busyDocId = null);
    }
  }

  String _formatTimestamp(dynamic value) {
    if (value == null) return '—';
    try {
      if (value is Timestamp) return DateFormat('dd MMM yyyy, hh:mm a').format(value.toDate());
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return AppTheme.green600;
      case 'rejected': return AppTheme.red600;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────
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
                16, MediaQuery.of(context).padding.top + 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  label: const Text('Back', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.cloud_upload, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.allowReviewActions ? 'Review uploads' : 'All uploads',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          widget.allowReviewActions
                              ? 'Approve or reject pending proof (officer only)'
                              : 'View-only — approvals are done by field officers',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search by Loan ID…',
                      prefixIcon: Icon(Icons.search, color: AppTheme.gray500),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'pending', 'approved', 'rejected'].map((s) {
                      final selected = _statusFilter == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s[0].toUpperCase() + s.substring(1),
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? Colors.white : AppTheme.gray700,
                                fontWeight: FontWeight.w600,
                              )),
                          selected: selected,
                          onSelected: (_) => setState(() => _statusFilter = s),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF7C3AED),
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          side: BorderSide(
                              color: selected ? Colors.transparent : AppTheme.gray300),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _staffQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return FirestoreStreamErrorPanel(
                    error: snapshot.error,
                    onRetry: () => setState(() {}),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data?.docs ?? [];
                
                // Officer assigned phones filter
                if (widget.allowReviewActions && AppSession.role == AppRole.officer) {
                  if (_assignedPhones == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  docs = docs.where((d) {
                    final phone = d.data()['phone'] as String? ?? '';
                    return _assignedPhones!.contains(phone);
                  }).toList();
                }

                // Client-side loanId filter
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data();
                    return (data['loanId'] as String? ?? '').toLowerCase().contains(_searchQuery);
                  }).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox, size: 56, color: AppTheme.gray300),
                        const SizedBox(height: 12),
                        Text('No $_statusFilter uploads',
                            style: const TextStyle(fontSize: 16, color: AppTheme.gray500)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _buildUploadCard(docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['status'] as String?) ?? 'pending';
    final imageUrl = resolveFirestoreImageUrl(data);
    final loanId = data['loanId'] as String? ?? '—';
    final userId = data['userId'] as String? ?? 'anonymous';
    final lat = data['latitude'];
    final lng = data['longitude'];
    final ts = data['createdAt'] ?? data['timestamp'];
    final reviewedBy = data['reviewedBy'] as String?;
    final reviewedAt = data['reviewedAt'];
    final isPending = status == 'pending';
    final busy = _busyDocId == doc.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor(status).withOpacity(0.25), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + status badge
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) => p == null
                              ? child
                              : Container(color: AppTheme.gray100,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(status[0].toUpperCase() + status.substring(1),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loan ID: $loanId',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.gray800)),
                const SizedBox(height: 4),
                Text('User: $userId',
                    style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
                const SizedBox(height: 8),
                if (lat != null && lng != null)
                  _row(Icons.location_on, const Color(0xFF7C3AED),
                      'GPS', '${(lat as num).toStringAsFixed(5)}, ${(lng as num).toStringAsFixed(5)}'),
                const SizedBox(height: 4),
                _row(Icons.access_time, AppTheme.blue600, 'Time', _formatTimestamp(ts)),
                if (!isPending && (reviewedBy != null || reviewedAt != null)) ...[
                  const SizedBox(height: 8),
                  if (reviewedBy != null)
                    _row(Icons.badge_outlined, AppTheme.gray600, 'Reviewed by', reviewedBy),
                  if (reviewedAt != null) ...[
                    const SizedBox(height: 4),
                    _row(Icons.event_available, AppTheme.gray600, 'Reviewed at', _formatTimestamp(reviewedAt)),
                  ],
                ],
                const SizedBox(height: 14),
                if (isPending && widget.allowReviewActions)
                  OfficerUploadReviewButtons(
                    show: true,
                    isBusy: busy,
                    onApprove: () => _onReviewTap(doc.id, 'approved'),
                    onReject: () => _onReviewTap(doc.id, 'rejected'),
                  )
                else if (isPending && !widget.allowReviewActions)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.amber600.withOpacity(0.35)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18, color: AppTheme.amber600),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Awaiting field officer review (read-only for admin)',
                            style: TextStyle(fontSize: 12, color: AppTheme.gray700),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusColor(status) == AppTheme.green600 ? Icons.check_circle : Icons.cancel,
                            size: 14, color: _statusColor(status)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            reviewedBy != null
                                ? '${status[0].toUpperCase()}${status.substring(1)} by officer $reviewedBy'
                                : '${status[0].toUpperCase()}${status.substring(1)}',
                            style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 200,
    color: AppTheme.gray100,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.broken_image_outlined, size: 40, color: AppTheme.gray400),
        SizedBox(height: 8),
        Text('Image unavailable', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
      ],
    ),
  );

  Widget _row(IconData icon, Color color, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.gray500, fontWeight: FontWeight.w500)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.gray700))),
    ],
  );
}
