import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  CONCERT_UPDATE,
  GROUP_MESSAGE,
  CARPOOL_MESSAGE,
  TICKET_UPDATE,
  USER_STATUS
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String message;
  final String? concertId;
  final String? chatRoomId;
  final String? ticketId;  // Add ticketId
  final String? senderId;
  final Timestamp timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    this.concertId,
    this.chatRoomId,
    this.ticketId,  // Add to constructor
    this.senderId,
    required this.timestamp,
    required this.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
      ),
      message: map['message'] ?? '',
      concertId: map['concertId'],
      chatRoomId: map['chatRoomId'],
      ticketId: map['ticketId'],  // Add to fromMap
      senderId: map['senderId'],
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'message': message,
      'concertId': concertId,
      'chatRoomId': chatRoomId,
      'ticketId': ticketId,  // Add to toMap
      'senderId': senderId,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}