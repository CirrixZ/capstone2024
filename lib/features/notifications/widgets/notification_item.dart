import 'package:capstone/core/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/notifications/models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final FirebaseService _firebaseService = FirebaseService();

  NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.CONCERT_UPDATE:
        return Icons.event_note;
      case NotificationType.GROUP_MESSAGE:
        return Icons.group;
      case NotificationType.CARPOOL_MESSAGE:
        return Icons.directions_car;
      case NotificationType.TICKET_UPDATE:
        return Icons.confirmation_number;
      case NotificationType.USER_STATUS:
        return Icons.person;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.CONCERT_UPDATE:
        return Colors.purple;
      case NotificationType.GROUP_MESSAGE:
        return Colors.blue;
      case NotificationType.CARPOOL_MESSAGE:
        return Colors.green;
      case NotificationType.TICKET_UPDATE:
        return Colors.orange;
      case NotificationType.USER_STATUS:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead
            ? const Color(0xFF2F1552)
            : const Color(0xFF3F2562),
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? null
            : Border.all(color: _getNotificationColor(), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _firebaseService.markNotificationAsRead(notification.id);
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(),
                    color: _getNotificationColor(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(notification.timestamp.toDate()),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
