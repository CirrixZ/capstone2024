import 'package:capstone/core/components/bottom_navbar.dart';
import 'package:capstone/core/helpers/custom_page_transitions.dart';
import 'package:capstone/features/notifications/screens/notification_settings.dart';
import 'package:capstone/features/notifications/widgets/notification_item.dart';
import 'package:capstone/features/notifications/widgets/notification_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/notifications/models/notification_model.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  NotificationType? _selectedType;
  bool _groupByDate = false;

  Map<NotificationType, String> get typeLabels => {
        NotificationType.CONCERT_UPDATE: 'Concert Updates',
        NotificationType.GROUP_MESSAGE: 'Group Messages',
        NotificationType.CARPOOL_MESSAGE: 'Carpool Messages',
        NotificationType.TICKET_UPDATE: 'Ticket Updates',
        NotificationType.USER_STATUS: 'User Updates',
      };

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Notifications', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF180B2D),
        actions: [
          // Group by toggle
          IconButton(
            icon: Icon(
              _groupByDate ? Icons.calendar_today : Icons.category,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _groupByDate = !_groupByDate),
            tooltip: _groupByDate ? 'Group by type' : 'Group by date',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _clearAllNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(
                context, AppPageRoute(page: NotificationSettingsPage())),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _firebaseService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text('No notifications yet',
                  style: TextStyle(color: Colors.white70)),
            );
          }

          // Filter by selected type if any
          var filteredNotifications = _selectedType == null
              ? notifications
              : notifications.where((n) => n.type == _selectedType).toList();

          if (_groupByDate) {
            // Group by date
            final groupedByDate = <String, List<NotificationModel>>{};
            for (var notification in filteredNotifications) {
              final dateHeader =
                  _getDateHeader(notification.timestamp.toDate());
              groupedByDate.putIfAbsent(dateHeader, () => []);
              groupedByDate[dateHeader]!.add(notification);
            }

            return Column(
              children: [
                if (_selectedType == null) _buildTypeFilter(),
                Expanded(
                  child: ListView.builder(
                    itemCount: groupedByDate.length,
                    itemBuilder: (context, index) {
                      final dateHeader = groupedByDate.keys.toList()[index];
                      final dateNotifications = groupedByDate[dateHeader]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              dateHeader,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...dateNotifications.map((notification) =>
                              _buildNotificationTile(notification)),
                          const Divider(color: Colors.white24),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          } else {
            // Group by type (existing implementation)
            final groupedByType = <NotificationType, List<NotificationModel>>{};
            for (var notification in filteredNotifications) {
              groupedByType.putIfAbsent(notification.type, () => []);
              groupedByType[notification.type]!.add(notification);
            }

            return Column(
              children: [
                _buildTypeFilter(),
                Expanded(
                  child: ListView.builder(
                    itemCount: groupedByType.length,
                    itemBuilder: (context, index) {
                      final type = groupedByType.keys.toList()[index];
                      final typeNotifications = groupedByType[type]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              typeLabels[type]!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...typeNotifications.map((notification) =>
                              _buildNotificationTile(notification)),
                          const Divider(color: Colors.white24),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('All'),
            selected: _selectedType == null,
            onSelected: (bool selected) {
              setState(() => _selectedType = null);
            },
            backgroundColor: const Color(0xFF2F1552),
            selectedColor: const Color(0xFF7000FF),
            labelStyle: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 8),
          ...typeLabels.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(entry.value),
                  selected: _selectedType == entry.key,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedType = selected ? entry.key : null;
                    });
                  },
                  backgroundColor: const Color(0xFF2F1552),
                  selectedColor: const Color(0xFF7000FF),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: NotificationItem(
          notification: notification,
          onTap: () => _handleNotificationTap(context, notification),
        ),
      ),
    );
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firebaseService.deleteNotification(notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: Color(0xFF7000FF),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2F1552),
          title: const Text('Clear All Notifications',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to delete all notifications?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firebaseService.clearAllNotifications();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications cleared'),
                        backgroundColor: Color(0xFF7000FF),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child:
                  const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => NotificationPreviewDialog(
        notification: notification,
        onView: () async {
          await _firebaseService.markNotificationAsRead(notification.id);
          if (!context.mounted) return;

          switch (notification.type) {
            case NotificationType.CONCERT_UPDATE:
              if (notification.concertId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BottomNavBar(
                      concertId: notification.concertId!, // Add the ! operator
                      initialIndex: 0,
                    ),
                  ),
                );
              }
              break;
            case NotificationType.GROUP_MESSAGE:
            case NotificationType.CARPOOL_MESSAGE:
              if (notification.chatRoomId != null) {
                Navigator.of(context).pushNamed(
                  '/chat-room',
                  arguments: {'chatRoomId': notification.chatRoomId},
                );
              }
              break;
            case NotificationType.TICKET_UPDATE:
              if (notification.concertId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BottomNavBar(
                      concertId: notification.concertId!, // Add the ! operator
                      initialIndex: 3, // Tickets tab index
                    ),
                  ),
                );
              }
              break;
            case NotificationType.USER_STATUS:
              break;
          }
        },
      ),
    );
  }
}
