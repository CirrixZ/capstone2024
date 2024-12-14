import 'package:capstone/core/helpers/custom_page_transitions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/messages/models/chat_preview_model.dart';
import 'package:capstone/features/chat/screens/carpool_chat_screen.dart';
import 'package:intl/intl.dart';

class CarpoolsTab extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  CarpoolsTab({super.key});

  Future<Map<String, String>> _getCarpoolDetails(String chatRoomId) async {
    // Search through all concerts to find the carpool
    QuerySnapshot concertSnapshot =
        await FirebaseFirestore.instance.collection('concerts').get();

    for (var concertDoc in concertSnapshot.docs) {
      QuerySnapshot carpoolSnapshot = await concertDoc.reference
          .collection('carpools')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      if (carpoolSnapshot.docs.isNotEmpty) {
        return {
          'concertId': concertDoc.id,
          'driverId': carpoolSnapshot.docs.first.get('driverId'),
        };
      }
    }

    throw Exception('Carpool details not found');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatPreview>>(
      stream: _firebaseService.getChatPreviews(
          _firebaseService.currentUser!.uid, 'carpool'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No carpool chats available.',
                  style: TextStyle(color: Colors.white)));
        }

        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.white),
          itemBuilder: (context, index) {
            final chatPreview = snapshot.data![index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
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
              onTap: () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Get the required details
                  final details = await _getCarpoolDetails(chatPreview.id);

                  // Hide loading indicator
                  Navigator.pop(context);

                  // Navigate to chat screen
                  Navigator.push(
                    context,
                    AppPageRoute(
                      page: CarpoolChatScreen(
                        carpoolId: chatPreview.id,
                        concertId: details['concertId']!,
                        driverId: details['driverId']!,
                      ),
                    ),
                  );
                } catch (e) {
                  // Hide loading indicator if showing
                  Navigator.of(context).pop();

                  // Show error dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error'),
                      content: Text('Could not open chat: ${e.toString()}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
