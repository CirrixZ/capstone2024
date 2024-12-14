import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/users/models/user_model.dart';

class MemberCard extends StatelessWidget {
  final UserModel user;
  final String? rsvpStatus;
  final bool canKick;
  final Function()? onKick;
  final bool isDriver;

  const MemberCard({
    super.key,
    required this.user,
    this.rsvpStatus,
    this.canKick = false,
    this.onKick,
    this.isDriver = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2F1552),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7000FF),
          child: Text(
            user.username[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                user.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user.firstName} ${user.lastName}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDriver)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.drive_eta,
                    color: Colors.amber),
              )
            else if (rsvpStatus != null) ...[
              Icon(_getRsvpIcon(rsvpStatus!),
                  color: _getRsvpColor(rsvpStatus!)),
              const SizedBox(width: 8),
            ],
            if (user.isSuperAdmin)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.security, color: Color(0xFF7000FF)),
              )
            else if (user.isAdmin)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.admin_panel_settings, color: Colors.blue),
              ),
            if (user.isBanned)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.block, color: Colors.red),
              ),
            if (canKick && !user.isAdmin && !user.isSuperAdmin)
              IconButton(
                icon:
                    const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => _showKickConfirmation(context),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRsvpColor(String status) {
    switch (status) {
      case 'going':
        return Colors.green;
      case 'maybe':
        return Colors.orange;
      case 'not_going':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRsvpIcon(String status) {
    switch (status) {
      case 'going':
        return Icons.check_circle;
      case 'maybe':
        return Icons.help_outline;
      case 'not_going':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  void _showKickConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2F1552),
        title: Text(
          'Kick Member',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove ${user.username} from this group?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onKick?.call();
            },
            child: Text(
              'Kick',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
