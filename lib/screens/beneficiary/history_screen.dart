import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/upload_history_query.dart';
import '../../utils/app_theme.dart';
import '../../utils/firestore_image_url.dart';
import '../../utils/firestore_query_helpers.dart';
import '../../services/app_session.dart';
import 'upload_history_detail_screen.dart';

/// Beneficiary upload history — live Firestore stream, card list, detail on tap.
///
/// Query: `uploads` where `role == beneficiary`, ordered by `createdAt` desc.
/// Requires a Firestore composite index on `role` + `createdAt` if not auto-created.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _scrollKey = GlobalKey<RefreshIndicatorState>();
  int _streamKey = 0;

  String _formatTimestamp(dynamic value) {
    if (value == null) return '—';
    try {
      if (value is Timestamp) {
        return DateFormat('dd MMM yyyy · hh:mm a').format(value.toDate());
      }
      return DateFormat('dd MMM yyyy · hh:mm a').format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  (Color bg, Color fg, IconData icon) _statusStyle(String status) {
    switch (status) {
      case 'approved':
        return (const Color(0xFFECFDF5), AppTheme.green600, Icons.check_circle_rounded);
      case 'rejected':
        return (const Color(0xFFFEF2F2), AppTheme.red600, Icons.cancel_rounded);
      default:
        return (const Color(0xFFFFFBEB), Colors.orange.shade800, Icons.schedule_rounded);
    }
  }

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() {});
  }

  void _openDetail(String docId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UploadHistoryDetailScreen(docId: docId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          _Header(onBack: () => Navigator.pop(context)),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(_streamKey),
              stream: UploadHistoryQuery.beneficiaryUploadsStream(AppSession.beneficiaryPhone ?? ''),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return FirestoreStreamErrorPanel(
                    error: snapshot.error,
                    onRetry: () => setState(() => _streamKey++),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _EmptyState(onBack: () => Navigator.pop(context));
                }

                return RefreshIndicator(
                  key: _scrollKey,
                  color: const Color(0xFF7C3AED),
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _UploadHistoryCard(
                      doc: docs[i],
                      formatTimestamp: _formatTimestamp,
                      statusStyle: _statusStyle,
                      onTap: () => _openDetail(docs[i].id),
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            label: const Text('Back', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload History',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Live updates from Firestore',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadHistoryCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String Function(dynamic) formatTimestamp;
  final (Color, Color, IconData) Function(String) statusStyle;
  final VoidCallback onTap;

  const _UploadHistoryCard({
    required this.doc,
    required this.formatTimestamp,
    required this.statusStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final status = (data['status'] as String?) ?? 'pending';
    final imageUrl = resolveFirestoreImageUrl(data);
    final loanId = data['loanId'] as String? ?? '—';
    final ts = data['createdAt'] ?? data['timestamp'];
    final (bg, fg, icon) = statusStyle(status);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.gray200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppTheme.gray100,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: fg.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: fg),
                        const SizedBox(width: 6),
                        Text(
                          status.isEmpty ? '—' : '${status[0].toUpperCase()}${status.substring(1)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Loan $loanId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.gray800,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppTheme.gray400, size: 22),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppTheme.gray500),
                      const SizedBox(width: 6),
                      Text(
                        formatTimestamp(ts),
                        style: const TextStyle(fontSize: 13, color: AppTheme.gray600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppTheme.gray100,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40, color: AppTheme.gray400),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDDD6FE), width: 2),
              ),
              child: const Icon(Icons.photo_library_outlined, size: 56, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No uploads yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.gray800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Submissions from the GPS camera flow will appear here in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.gray500, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Go back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(180, 48),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
