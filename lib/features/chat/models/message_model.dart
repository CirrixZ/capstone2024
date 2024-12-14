import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      senderId: map['senderId'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      timestamp: map['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }

  bool isSameDay(Message other) {
    return timestamp.toDate().year == other.timestamp.toDate().year &&
           timestamp.toDate().month == other.timestamp.toDate().month &&
           timestamp.toDate().day == other.timestamp.toDate().day;
  }

  bool isSignificantTimeDifference(Message other) {
    return timestamp.toDate().difference(other.timestamp.toDate()).inMinutes.abs() > 30;
  }
}