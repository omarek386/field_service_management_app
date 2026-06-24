import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const String _notificationsBoxName = 'notifications_box';
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final box = await Hive.openBox(_notificationsBoxName);
    
    // Seed mock notifications if empty
    if (box.isEmpty) {
      final mockData = [
        {
          'id': 'notif_1',
          'title': 'New Job Assigned',
          'body': 'You have been assigned: Internet Fiber Installation for Ahmad Al-Fayed.',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          'read': false,
        },
        {
          'id': 'notif_2',
          'title': 'Upcoming Job Reminder',
          'body': 'Your scheduled service for John Doe starts in 1 hour.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'read': false,
        },
        {
          'id': 'notif_3',
          'title': 'Sync Completed',
          'body': 'Service Report for job_003 successfully synchronized with Firestore.',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'read': true,
        },
      ];
      for (var item in mockData) {
        await box.put(item['id'], item);
      }
    }

    final List<Map<String, dynamic>> loadedList = [];
    for (var key in box.keys) {
      final map = Map<String, dynamic>.from(box.get(key) as Map);
      loadedList.add(map);
    }

    // Sort by timestamp desc
    loadedList.sort((a, b) {
      final tA = DateTime.tryParse(a['timestamp'] as String) ?? DateTime.now();
      final tB = DateTime.tryParse(b['timestamp'] as String) ?? DateTime.now();
      return tB.compareTo(tA);
    });

    setState(() {
      _notifications = loadedList;
    });
  }

  Future<void> _markAllAsRead() async {
    final box = await Hive.openBox(_notificationsBoxName);
    for (var item in _notifications) {
      final updated = Map<String, dynamic>.from(item);
      updated['read'] = true;
      await box.put(updated['id'], updated);
    }
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => n['read'] == false))
            IconButton(
              icon: const Icon(Icons.mark_chat_read_outlined),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final isUnread = notif['read'] == false;
                final rawTime = DateTime.tryParse(notif['timestamp'] as String) ?? DateTime.now();
                final formattedTime = DateFormat('MMM dd, hh:mm a').format(rawTime);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isUnread
                          ? theme.colorScheme.primary.withOpacity(0.3)
                          : theme.colorScheme.outlineVariant.withOpacity(0.5),
                      width: isUnread ? 1.5 : 1.0,
                    ),
                  ),
                  color: isUnread
                      ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                      : theme.colorScheme.surface,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isUnread
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.surfaceVariant,
                      child: Icon(
                        isUnread ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                        color: isUnread ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      notif['title'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          notif['body'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isUnread ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedTime,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (isUnread) {
                        final box = await Hive.openBox(_notificationsBoxName);
                        final updated = Map<String, dynamic>.from(notif);
                        updated['read'] = true;
                        await box.put(updated['id'], updated);
                        _loadNotifications();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
