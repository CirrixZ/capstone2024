import 'package:capstone/core/helpers/custom_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/messages/models/chat_preview_model.dart';
import 'package:capstone/features/chat/screens/group_chat_screen.dart';
import 'package:intl/intl.dart';

class GroupChatsTab extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  GroupChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatPreview>>(
      stream: _firebaseService.getChatPreviews(
          _firebaseService.currentUser!.uid, 'group'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text('No group chats available.',
                  style: TextStyle(color: Colors.white)));
        }

        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.white),
          itemBuilder: (context, index) {
            final chatPreview = snapshot.data![index];
            return ListTile(
              leading: CircleAvatar(child: Icon(Icons.group)),
              title:
                  Text(chatPreview.name, style: TextStyle(color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chatPreview.concertName,
                      style: TextStyle(color: Colors.white24)),
                  Text(chatPreview.lastMessage,
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('h:mm a')
                        .format(chatPreview.lastMessageTime.toDate()),
                    style: TextStyle(color: Colors.white54),
                  ),
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
              onTap: () {
                Navigator.push(
                  context,
                  AppPageRoute(
                    page: GroupChatScreen(
                      groupId: chatPreview.id,
                      concertId: chatPreview.concertId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
