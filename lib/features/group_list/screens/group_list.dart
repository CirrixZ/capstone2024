import 'package:capstone/core/components/custom_dialog.dart';
import 'package:capstone/features/chat/screens/group_chat_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/components/floating_action_button.dart';
import 'package:capstone/features/group_list/models/group_model.dart';
import 'package:capstone/features/group_list/widgets/group_card.dart';
import 'package:capstone/core/services/firebase_service.dart';

class GroupList extends StatelessWidget {
  final bool isAdmin;
  final String concertId;
  final bool isVerified; // New parameter
  final FirebaseService _firebaseService = FirebaseService();

  GroupList({
    super.key,
    required this.isAdmin,
    required this.concertId,
    this.isVerified = false, // Default to false
  });

  // Method to create group
  void _showAddGroupDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Create New Group',
        requiresImage: true,
        imageHint: 'Add Group Banner',
        fields: [
          CustomDialogField(
            label: 'Group Name',
            hint: 'Enter group name',
            controller: nameController,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a group name';
              }
              return null;
            },
          ),
        ],
        onSubmit: (values, image) async {
          if (image == null) return;

          final String fileName =
              'group_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance.ref().child(fileName);
          await ref.putFile(image);
          final String imageUrl = await ref.getDownloadURL();

          await _firebaseService.createGroup(
            concertId: concertId,
            groupName: values['Group Name']!,
            imageUrl: imageUrl,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Group List',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Group>>(
                  stream: _firebaseService.getGroups(concertId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No groups available.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      padding: const EdgeInsets.only(
                          bottom: 60), // Add padding for FAB
                      itemBuilder: (context, index) {
                        Group group = snapshot.data![index];
                        return GroupCard(
                          group: group,
                          concertId: concertId,
                          onJoin: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupChatScreen(
                                  groupId: group.chatRoomId,
                                  concertId: concertId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: isAdmin
            ? CustomFloatingActionButton(
                labelText: 'Add Group',
                iconData: Icons.add,
                onPressed: () => _showAddGroupDialog(context),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
  }
}
