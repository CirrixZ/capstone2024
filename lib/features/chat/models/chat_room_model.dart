import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String name;
  final List<String> participants;
  final String type; // 'group' or 'carpool'
  final String? lastMessage;
  final Timestamp? lastMessageTimestamp;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants,
    required this.type,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      name: map['name'],
      participants: List<String>.from(map['participants']),
      type: map['type'],
      lastMessage: map['lastMessage'],
      lastMessageTimestamp: map['lastMessageTimestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'participants': participants,
      'type': type,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
  }
}
