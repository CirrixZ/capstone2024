import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/users/models/user_model.dart';
import 'package:capstone/features/shared/widgets/member_card.dart';

class GroupInfoPage extends StatefulWidget {
  final String groupId;
  final String concertId;

  const GroupInfoPage({
    super.key,
    required this.groupId,
    required this.concertId,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<bool> _isAdminStream;

  @override
  void initState() {
    super.initState();
    _isAdminStream = _firebaseService.userAdminStream();
  }

  Future<void> _handleKickMember(String userId) async {
    try {
      await _firebaseService.kickFromGroup(
        widget.groupId,
        userId,
        widget.concertId, // Add the concertId parameter
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member has been removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleLeaveGroup() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2F1552),
        title: const Text(
          'Leave Group',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to leave this group? You won\'t be able to rejoin later.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Leave',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      try {
        await _firebaseService.leaveGroup(widget.groupId, widget.concertId);
        if (mounted) {
          // Navigate back to the previous screen or home
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have left the group')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF180B2D),
        actions: [
          // Show leave button for non-creator members
          StreamBuilder<DocumentSnapshot>(
            stream: _firebaseService.getGroupDetails(widget.groupId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final groupData = snapshot.data!.data() as Map<String, dynamic>?;
              final currentUserId = _firebaseService.currentUser?.uid;

              // Don't show leave button for creator or if user info isn't loaded
              if (currentUserId == null ||
                  groupData?['createdBy'] == currentUserId) {
                return const SizedBox();
              }

              return IconButton(
                icon: const Icon(Icons.exit_to_app),
                color: Colors.red,
                onPressed: _handleLeaveGroup,
                tooltip: 'Leave Group',
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firebaseService.getGroupDetails(widget.groupId),
        builder: (context, groupSnapshot) {
          if (groupSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!groupSnapshot.hasData || !groupSnapshot.data!.exists) {
            return const Center(child: Text('Group not found'));
          }

          final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Info Card
                Card(
                  color: const Color(0xFF2F1552),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                groupData['name'] ?? 'Group Name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Concert: ${groupData['concertName'] ?? ''}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Members Section
                const Text(
                  'Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<UserModel>>(
                  stream: _firebaseService.getChatRoomMembers(widget.groupId),
                  builder: (context, membersSnapshot) {
                    if (!membersSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return StreamBuilder<bool>(
                      stream: _isAdminStream,
                      builder: (context, adminSnapshot) {
                        final isAdmin = adminSnapshot.data ?? false;
                        final currentUserId = _firebaseService.currentUser?.uid;

                        return Column(
                          children: membersSnapshot.data!.map((user) {
                            // Check if current user is admin or the group creator
                            final canKick = isAdmin ||
                                (currentUserId == groupData['createdBy'] &&
                                    currentUserId != user.id);

                            return MemberCard(
                              user: user,
                              canKick: canKick,
                              onKick: canKick
                                  ? () => _handleKickMember(user.id)
                                  : null,
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
