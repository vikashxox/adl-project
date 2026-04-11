import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/app_session.dart';
import '../../utils/app_theme.dart';

/// Shows the current user's upload history from the `uploads` Firestore
/// collection, filtered by [AppSession.userId].
///
/// Each item displays the image thumbnail, status badge, and timestamp.
/// Uses [StreamBuilder] for real-time updates.
class UserHistoryScreen extends StatelessWidget {
  const UserHistoryScreen({super.key});

  static Stream<QuerySnapshot<Map<String, dynamic>>> _stream(String userId) {
    return FirebaseFirestore.instance
        .collection('uploads')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static String _formatTs(dynamic value) {
    if (value == null) return '—';
    try {
      final dt =
          value is Timestamp ? value.toDate() : DateTime.parse(value.toString());
      return DateFormat('dd MMM yyyy · hh:mm a').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  static ({Color bg, Color fg, IconData icon}) _statusStyle(String status) =>
      switch (status) {
        'approved' => (
            bg: const Color(0xFFECFDF5),
            fg: AppTheme.green600,
            icon: Icons.check_circle_rounded,
          ),
        'rejected' => (
            bg: const Color(0xFFFEF2F2),
            fg: AppTheme.red600,
            icon: Icons.cancel_rounded,
          ),
        _ => (
            bg: const Color(0xFFFFFBEB),
            fg: Colors.orange.shade800,
            icon: Icons.schedule_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final userId = AppSession.userId;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: userId == null || userId.isEmpty
                ? _buildNotLoggedIn(context)
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _stream(userId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildError(snapshot.error);
                      }
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          snapshot.data == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) return _buildEmpty(context);
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _UploadCard(
                          data: docs[i].data(),
                          formatTs: _formatTs,
                          statusStyle: _statusStyle,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            label: const Text('Back',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
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
                child:
                    const Icon(Icons.history, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Upload History',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Live updates from Firestore',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined,
                  size: 56, color: AppTheme.gray400),
              const SizedBox(height: 16),
              const Text('Not logged in',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray800)),
              const SizedBox(height: 8),
              const Text('Please log in to view your upload history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.gray500, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(160, 48),
                  elevation: 0,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );

  Widget _buildError(Object? error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppTheme.red600),
              const SizedBox(height: 12),
              const Text('Failed to load history',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray800)),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.gray500),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty(BuildContext context) => Center(
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
                  border:
                      Border.all(color: const Color(0xFFDDD6FE), width: 2),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    size: 56, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(height: 24),
              const Text('No uploads yet',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray800)),
              const SizedBox(height: 8),
              const Text(
                'Your submitted uploads will appear here in real time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.gray500, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(180, 48),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class _UploadCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(dynamic) formatTs;
  final ({Color bg, Color fg, IconData icon}) Function(String) statusStyle;

  const _UploadCard({
    required this.data,
    required this.formatTs,
    required this.statusStyle,
  });

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] as String?) ?? 'pending';
    final imageUrl = data['imageUrl'] as String?;
    final ts = data['createdAt'] ?? data['timestamp'];
    final style = statusStyle(status);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.gray200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image with status badge overlay ───────────────────────────────
          Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: imageUrl != null && imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                color: AppTheme.gray100,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: style.fg.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 14, color: style.fg),
                      const SizedBox(width: 6),
                      Text(
                        status.isEmpty
                            ? '—'
                            : status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: style.fg),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Timestamp row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: AppTheme.gray500),
                const SizedBox(width: 6),
                Text(
                  formatTs(ts),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.gray100,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 40, color: AppTheme.gray400),
        ),
      );
}
