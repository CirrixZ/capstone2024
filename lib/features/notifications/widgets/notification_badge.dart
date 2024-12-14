// lib/features/notifications/widgets/notification_badge.dart

import 'package:capstone/core/helpers/custom_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/notifications/models/notification_model.dart';
import 'package:capstone/features/notifications/screens/notifications.dart';

class NotificationIconButton extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  NotificationIconButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _firebaseService.getUserNotifications(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                      context,
                      AppPageRoute(page: NotificationsPage()),
                    );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7000FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}