import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPreview {
  final String id;
  final String name;
  final String concertName;
  final String subtitle;  // For carpool title or extra info
  final String lastMessage;
  final Timestamp lastMessageTime;
  final String type;
  final bool hasUnread;
  final String? senderId; // Add this for profile pictures
  final String concertId;

  ChatPreview({
    required this.id,
    required this.name,
    required this.concertName,
    required this.subtitle,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.type,
    required this.hasUnread,
    required this.concertId,
    this.senderId,
  });

  factory ChatPreview.fromMap(Map<String, dynamic> map, String id, bool hasUnread, String subtitle) {
    return ChatPreview(
      id: id,
      name: map['name'] ?? '',
      concertName: map['concertName'] ?? '',
      subtitle: subtitle,
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] ?? Timestamp.now(),
      type: map['type'] ?? '',
      hasUnread: hasUnread,
      senderId: map['senderId'],
      concertId: map['concertId'] ?? '',  // Add this
    );
  }
}