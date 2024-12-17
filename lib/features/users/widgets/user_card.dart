import 'package:capstone/features/users/widgets/ban_dialog.dart';
import 'package:capstone/features/users/widgets/ban_history_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/users/models/user_model.dart';
import 'package:capstone/core/services/firebase_service.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final FirebaseService _firebaseService = FirebaseService();

  UserCard({
    super.key,
    required this.user,
  });

  Future<void> _showActionDialog(
      BuildContext context, bool isSuperAdmin) async {
    // Get super admin status
    bool isSuperAdmin = await _firebaseService.isUserAdmin();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2F1552),
          title: Text(
            user.username,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!user.isAdmin && !user.isSuperAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings,
                      color: Colors.blue),
                  title: const Text('Promote to Admin',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    print('Attempting to promote user');
                    if (!isSuperAdmin) {
                      print('Showing permission denied dialog');
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Permission Denied'),
                          content: const Text(
                              'Only Super Admins can promote users.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      await _firebaseService.promoteUser(user.id);
                      Navigator.pop(context);
                    }
                  },
                ),
              if (!user.isBanned &&
                  !user.isSuperAdmin &&
                  user.id != _firebaseService.currentUser?.uid)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Ban User',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => BanManagementDialog(
                        user: user,
                        isSuperAdmin: isSuperAdmin,
                        onBanConfirmed: (duration, reason) async {
                          await _firebaseService.banUser(
                            user.id,
                            reason: reason,
                            duration: duration,
                          );
                        },
                      ),
                    );
                  },
                ),
              if (user.isBanned)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Unban User',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await _firebaseService.unbanUser(user.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              if (user.isAdmin && !user.isSuperAdmin)
                ListTile(
                  leading:
                      const Icon(Icons.person_remove, color: Colors.orange),
                  title: const Text('Demote from Admin',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    // Only allow super admins to demote
                    if (!isSuperAdmin) {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Permission Denied'),
                          content:
                              const Text('Only Super Admins can demote users.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      await _firebaseService.demoteAdmin(user.id);
                      Navigator.pop(context);
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.orange),
                title: const Text('View Ban History',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => BanHistoryDialog(user: user),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2F1552),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7000FF),
          backgroundImage: user.profilePicture != null
              ? NetworkImage(user.profilePicture!)
              : null,
          child: user.profilePicture == null
              ? Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              user.username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // Add email verification status
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData =
                      snapshot.data?.data() as Map<String, dynamic>?;
                  final isVerified = userData?['emailVerified'] ?? false;
                  return Tooltip(
                    message:
                        isVerified ? 'Email Verified' : 'Email Not Verified',
                    child: Icon(
                      isVerified ? Icons.verified_user : Icons.warning,
                      color: isVerified ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        subtitle: Text(
          '${user.firstName} ${user.lastName}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.isSuperAdmin)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.security,
                    color: Color(
                        0xFF7000FF)), // Purple security icon for super admin
              )
            else if (user.isAdmin)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.admin_panel_settings,
                    color: Colors.blue), // Blue icon for normal admin
              ),
            if (user.isBanned)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.block, color: Colors.red),
              ),
            StreamBuilder<bool>(
              stream: _firebaseService.userAdminStream(),
              builder: (context, snapshot) {
                print('Admin Stream Snapshot: ${snapshot.data}');
                final isSuperAdmin = snapshot.data ?? false;
                return IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onPressed: () => _showActionDialog(context, isSuperAdmin),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
