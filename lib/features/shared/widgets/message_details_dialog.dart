import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:capstone/features/chat/models/message_model.dart';
import 'package:capstone/core/services/firebase_service.dart';

class MessageDetailsDialog extends StatelessWidget {
  final Message message;
  final String chatRoomId;
  final bool isMe;

  const MessageDetailsDialog({
    super.key,
    required this.message,
    required this.chatRoomId,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseService _firebaseService = FirebaseService();

    return AlertDialog(
      backgroundColor: const Color(0xFF2F1552),
      title: const Text(
        'Message Details',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.4, // 40% of screen height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sent at: ${DateFormat('MMM d, y').add_jm().format(message.timestamp.toDate())}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              if (message.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF2F1552),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              else
                Text(
                  'Message: ${message.text}',
                  style: const TextStyle(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        if (isMe) // Only show delete option for own messages
          TextButton(
            onPressed: () async {
              try {
                await _firebaseService.deleteMessage(chatRoomId, message.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
