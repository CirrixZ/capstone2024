import 'package:flutter/material.dart';
import 'package:capstone/features/messages/models/chat_preview_model.dart';
import 'package:intl/intl.dart';

class GroupChatPreview extends StatelessWidget {
  final ChatPreview chatPreview;
  final VoidCallback onTap;

  const GroupChatPreview({
    Key? key,
    required this.chatPreview,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(Icons.group, color: Colors.white),
        backgroundColor: Color(0xFF2F1552),
      ),
      title: Text(chatPreview.name, style: TextStyle(color: Colors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chatPreview.concertName,
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
