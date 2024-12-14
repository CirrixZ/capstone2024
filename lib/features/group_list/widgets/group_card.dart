import 'package:capstone/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/group_list/models/group_model.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/chat/screens/group_chat_screen.dart';

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onJoin;
  final String concertId; // Add this
  final FirebaseService _firebaseService = FirebaseService(); // Add this

  GroupCard({
    Key? key,
    required this.group,
    required this.onJoin,
    required this.concertId, // Add this
  }) : super(key: key);

  Future<void> _showDeleteDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2F1552),
          title: Text('Delete Group', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete this group? This will delete the group chat as well.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await _firebaseService.deleteGroup(
                    concertId,
                    group.id,
                    group.chatRoomId,
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _firebaseService.userAdminStream(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;

        return Stack(
          children: [
            Card(
              color: const Color(0xff2F1552),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        group.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      group.groupName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: AppColors.iconColor),
                            SizedBox(width: 5),
                            Text(
                              '${group.membersCount} Members',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await _firebaseService.joinGroup(
                                  concertId, group.id);
                              if (context.mounted) {
                                // Add this check
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => GroupChatScreen(
                                      groupId: group.chatRoomId,
                                      concertId: concertId,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                // Add this check
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error joining group: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            side: BorderSide(
                              width: 2.0,
                              color: AppColors.borderColor,
                            ),
                            backgroundColor: const Color(0xFF2F1552),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 14),
                          ),
                          child: Text(
                            'Click to Join',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isAdmin)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ),
          ],
        );
      },
    );
  }
}
