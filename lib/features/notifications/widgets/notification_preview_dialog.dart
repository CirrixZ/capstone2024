// lib/features/notifications/widgets/notification_preview_dialog.dart

import 'package:capstone/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/chat/models/chat_room_model.dart';
import 'package:capstone/features/concerts/models/concert_model.dart';
import 'package:capstone/features/notifications/models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPreviewDialog extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onView;

  const NotificationPreviewDialog({
    super.key,
    required this.notification,
    required this.onView,
  });

  @override
  State<NotificationPreviewDialog> createState() =>
      _NotificationPreviewDialogState();
}

class _NotificationPreviewDialogState extends State<NotificationPreviewDialog> {
  final FirebaseService _firebaseService = FirebaseService();

  String _getButtonText() {
    switch (widget.notification.type) {
      case NotificationType.USER_STATUS:
        return 'Done';
      case NotificationType.GROUP_MESSAGE:
      case NotificationType.CARPOOL_MESSAGE:
        return 'View Chat';
      case NotificationType.CONCERT_UPDATE:
      case NotificationType.TICKET_UPDATE:
        return 'View Details';
    }
  }

  Widget _buildPreviewContent() {
    switch (widget.notification.type) {
      case NotificationType.CONCERT_UPDATE:
      case NotificationType.TICKET_UPDATE:
        if (widget.notification.concertId == null) {
          return _buildErrorWidget('Concert information not available');
        }

        return FutureBuilder<Concert>(
          future: _firebaseService
              .getConcertDetails(widget.notification.concertId!)
              .first,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _buildErrorWidget('Concert may have been deleted');
            }

            // Add this null check
            try {
              return _buildConcertPreview(snapshot.data!);
            } catch (e) {
              return _buildErrorWidget('Concert information unavailable');
            }
          },
        );

      case NotificationType.GROUP_MESSAGE:
      case NotificationType.CARPOOL_MESSAGE:
        if (widget.notification.chatRoomId == null) {
          return _buildErrorWidget('Chat information not available');
        }

        return FutureBuilder<List<ChatRoom>>(
          future: _firebaseService
              .getChatRooms(_firebaseService.currentUser!.uid)
              .first,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _buildErrorWidget('Unable to load chat details');
            }

            try {
              final chatRoom = snapshot.data!.firstWhere(
                (room) => room.id == widget.notification.chatRoomId,
              );
              return _buildChatPreview(chatRoom);
            } catch (e) {
              // This will catch the case when the chat room is not found
              return _buildErrorWidget('Chat room has been deleted');
            }
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7000FF)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcertPreview(Concert concert) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              concert.imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                color: Colors.grey[800],
                child: const Icon(Icons.music_note, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concert.artistName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  concert.concertName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPreview(ChatRoom chatRoom) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            widget.notification.type == NotificationType.GROUP_MESSAGE
                ? Icons.group
                : Icons.directions_car,
            color: Colors.white70,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatRoom.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (chatRoom.lastMessage != null)
                  Text(
                    chatRoom.lastMessage!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (widget.notification.type) {
      case NotificationType.CONCERT_UPDATE:
        icon = Icons.event_note;
        color = Colors.purple;
        break;
      case NotificationType.GROUP_MESSAGE:
        icon = Icons.group;
        color = Colors.blue;
        break;
      case NotificationType.CARPOOL_MESSAGE:
        icon = Icons.directions_car;
        color = Colors.green;
        break;
      case NotificationType.TICKET_UPDATE:
        icon = Icons.confirmation_number;
        color = Colors.orange;
        break;
      case NotificationType.USER_STATUS:
        icon = Icons.person;
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getTypeTitle() {
    switch (widget.notification.type) {
      case NotificationType.CONCERT_UPDATE:
        return 'Concert Update';
      case NotificationType.GROUP_MESSAGE:
        return 'New Group Message';
      case NotificationType.CARPOOL_MESSAGE:
        return 'New Carpool Message';
      case NotificationType.TICKET_UPDATE:
        return 'Ticket Update';
      case NotificationType.USER_STATUS:
        return 'User Update';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2F1552),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTypeTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeago.format(widget.notification.timestamp.toDate()),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.notification.message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildPreviewContent(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close',
                      style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _firebaseService.handleNotificationNavigation(
                        context, widget.notification);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7000FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_getButtonText(),
                      style: TextStyle(color: AppColors.textWhite)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
