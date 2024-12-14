import 'package:flutter/material.dart';
import 'package:capstone/features/messages/models/chat_preview_model.dart';
import 'package:intl/intl.dart';
import 'package:capstone/core/services/firebase_service.dart'; // Add this

class CarpoolChatPreview extends StatelessWidget {
  final ChatPreview chatPreview;
  final VoidCallback onTap;
  final FirebaseService _firebaseService = FirebaseService(); // Add this

  CarpoolChatPreview({
    Key? key,
    required this.chatPreview,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<Map<String, dynamic>>(
        future: _firebaseService.getUserData(
            chatPreview.senderId ?? ''), // Add senderId to ChatPreview model
        builder: (context, snapshot) {
          return CircleAvatar(
            backgroundImage:
                snapshot.hasData && snapshot.data?['profilePicture'] != null
                    ? NetworkImage(snapshot.data!['profilePicture'])
                    : null,
            child:
                (!snapshot.hasData || snapshot.data?['profilePicture'] == null)
                    ? Icon(Icons.person, color: Colors.white)
                    : null,
          );
        },
      ),
      title: Text(chatPreview.name, style: TextStyle(color: Colors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chatPreview.subtitle, // Use subtitle instead of concertName
            style: TextStyle(color: Colors.white24),
          ),
          Text(chatPreview.lastMessage,
              style: TextStyle(color: Colors.white54)),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
              DateFormat('h:mm a').format(chatPreview.lastMessageTime.toDate()),
              style: TextStyle(color: Colors.white54)),
          SizedBox(height: 5),
          if (chatPreview.hasUnread)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
