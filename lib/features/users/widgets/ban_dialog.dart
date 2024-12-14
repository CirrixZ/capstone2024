import 'package:flutter/material.dart';
import 'package:capstone/features/users/models/user_model.dart';

class BanDuration {
  final String label;
  final Duration duration;
  final bool isPermanent;

  const BanDuration({
    required this.label,
    required this.duration,
    this.isPermanent = false,
  });
}

class BanManagementDialog extends StatelessWidget {
  final UserModel user;
  final Function(Duration?, String) onBanConfirmed;
  final bool isSuperAdmin;

  const BanManagementDialog({
    Key? key,
    required this.user,
    required this.onBanConfirmed,
    this.isSuperAdmin = false,
  }) : super(key: key);

  static const List<BanDuration> banDurations = [
    BanDuration(label: '1 Day', duration: Duration(days: 1)),
    BanDuration(label: '3 Days', duration: Duration(days: 3)),
    BanDuration(label: '7 Days', duration: Duration(days: 7)),
    BanDuration(label: '30 Days', duration: Duration(days: 30)),
    BanDuration(label: 'Permanent', duration: Duration.zero, isPermanent: true),
  ];

  @override
  Widget build(BuildContext context) {
    // Prevent banning super admins
    if (user.isSuperAdmin) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2F1552),
        title: const Text(
          'Cannot Ban Super Admin',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Super administrators cannot be banned.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white70)),
          ),
        ],
      );
    }

    // Prevent non-super admins from banning admins
    if (user.isAdmin && !isSuperAdmin) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2F1552),
        title: const Text(
          'Cannot Ban Admin',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Only super administrators can ban other administrators.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white70)),
          ),
        ],
      );
    }
    final reasonController = TextEditingController();

    return AlertDialog(
      backgroundColor: const Color(0xFF2F1552),
      title: Text(
        'Ban ${user.username}',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Ban Duration:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            ...banDurations.map((duration) => ListTile(
                  title: Text(
                    duration.label,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a ban reason')),
                      );
                      return;
                    }
                    onBanConfirmed(
                      duration.isPermanent ? null : duration.duration,
                      reasonController.text,
                    );
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Ban Reason',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7000FF)),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
