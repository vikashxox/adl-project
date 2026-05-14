import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/app_session.dart';
import '../utils/app_theme.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  DateTime? _lastReadDate;
  DateTime _sessionStart = DateTime.now();
  StreamSubscription<QuerySnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  List<Map<String, dynamic>> get _localNotifications {
    final list = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (AppSession.role == AppRole.beneficiary && AppSession.deadline != null) {
      try {
        final d = DateTime.parse(AppSession.deadline!);
        final diff = d.difference(today).inDays;
        
        if (diff == 0) {
          list.add({
            'title': 'Submission Deadline',
            'message': 'Today is your last date for submission!',
            'createdAt': Timestamp.fromDate(today),
          });
        } else if (diff <= 3 && diff > 0) {
          list.add({
            'title': 'Submission Deadline Near',
            'message': 'You have $diff days left for submission.',
            'createdAt': Timestamp.fromDate(today),
          });
        }
      } catch (_) {}
    }
    return list;
  }

  Future<void> _initNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReadMs = prefs.getInt('last_read_notifications');
    if (lastReadMs != null) {
      _lastReadDate = DateTime.fromMillisecondsSinceEpoch(lastReadMs);
    }

    final roleStr = AppSession.role.name; // 'admin', 'officer', 'beneficiary'

    _sub = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;

      int unread = 0;
      bool hasNewLivePopup = false;
      Map<String, dynamic>? newLiveNotification;

      for (var change in snap.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>;
        
        final tr = data['targetRole'] as String? ?? 'all';
        if (tr != 'all' && tr != roleStr) continue;

        final tp = data['targetPhone'] as String?;
        if (tp != null && tp.isNotEmpty) {
          if (roleStr != 'beneficiary' || AppSession.beneficiaryPhone != tp) continue;
        }

        DateTime? createdAt;
        if (data['createdAt'] != null) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        }

        if (createdAt != null) {
          // Check for badge count
          if (_lastReadDate == null || createdAt.isAfter(_lastReadDate!)) {
            unread++;
          }

          // Check for live popup (only added during this session, and after session start)
          if (change.type == DocumentChangeType.added && createdAt.isAfter(_sessionStart)) {
            hasNewLivePopup = true;
            newLiveNotification = data;
          }
        }
      }

      // Add local unread count
      for (var local in _localNotifications) {
        final createdAt = (local['createdAt'] as Timestamp).toDate();
        if (_lastReadDate == null || createdAt.isAfter(_lastReadDate!)) {
          unread++;
          // Trigger live popup for local if not shown this session
          if (createdAt.isAfter(_sessionStart) || _lastReadDate == null) {
            hasNewLivePopup = true;
            newLiveNotification ??= local;
          }
        }
      }

      setState(() => _unreadCount = unread);

      if (hasNewLivePopup && newLiveNotification != null) {
        _showLivePopup(newLiveNotification!);
        _sessionStart = DateTime.now();
      }
    });
  }

  void _showLivePopup(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data['title'] ?? 'New Notification', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(data['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFDC2626), // Red alert
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: _showNotificationsSheet,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _showNotificationsSheet() async {
    // Mark as read
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_notifications', DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _lastReadDate = DateTime.now();
      _unreadCount = 0;
    });

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.gray50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications, color: AppTheme.purple600),
                        SizedBox(width: 8),
                        Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gray800)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.gray500),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .orderBy('createdAt', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading notifications.', style: TextStyle(color: AppTheme.gray500)));
                    }

                    final firestoreDocs = snapshot.hasData 
                        ? snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>)
                            .where((data) {
                              final tr = data['targetRole'] as String? ?? 'all';
                              if (tr != 'all' && tr != AppSession.role.name) return false;
                              final tp = data['targetPhone'] as String?;
                              if (tp != null && tp.isNotEmpty) {
                                if (AppSession.role.name != 'beneficiary' || AppSession.beneficiaryPhone != tp) return false;
                              }
                              return true;
                            }).toList() 
                        : <Map<String, dynamic>>[];
                    final allNotifications = [...firestoreDocs, ..._localNotifications];
                    
                    allNotifications.sort((a, b) {
                      DateTime? dateA = a['createdAt'] != null ? (a['createdAt'] as Timestamp).toDate() : null;
                      DateTime? dateB = b['createdAt'] != null ? (b['createdAt'] as Timestamp).toDate() : null;
                      if (dateA == null && dateB == null) return 0;
                      if (dateA == null) return 1;
                      if (dateB == null) return -1;
                      return dateB.compareTo(dateA);
                    });

                    if (allNotifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: allNotifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = allNotifications[index];
                        DateTime? date;
                        if (data['createdAt'] != null) {
                          date = (data['createdAt'] as Timestamp).toDate();
                        }
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.gray200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(data['title'] ?? 'Notification', 
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.gray800)),
                                  ),
                                  if (date != null)
                                    Text(DateFormat('dd MMM hh:mm a').format(date), 
                                      style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(data['message'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.gray600)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined, size: 48, color: AppTheme.gray300),
          ),
          const SizedBox(height: 16),
          const Text('No Notifications Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
          const SizedBox(height: 8),
          const Text('When there are updates, they will appear here.', style: TextStyle(fontSize: 13, color: AppTheme.gray500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showNotificationsSheet,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications, size: 24, color: Colors.white),
            if (_unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
