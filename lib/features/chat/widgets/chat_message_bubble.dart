import 'package:capstone/features/shared/widgets/message_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/chat/models/message_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onTap;
  final String chatRoomId;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.chatRoomId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(  // Wrap with GestureDetector
      onTap: message.imageUrl != null ? onTap : null,
      onLongPress: () {
    showDialog(
      context: context,
      builder: (context) => MessageDetailsDialog(
        message: message,
        chatRoomId: chatRoomId, // Add this prop to ChatMessageBubble
        isMe: isMe,
      ),
    );
  },
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64.0 : 0.0,
          right: isMe ? 0.0 : 64.0,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isMe ? Color(0xFF7000FF) : Color(0xFF2F1552),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}