import 'package:flutter/material.dart';
import 'package:capstone/features/users/models/user_model.dart';
import 'package:intl/intl.dart';

class BanHistoryDialog extends StatelessWidget {
  final UserModel user;

  const BanHistoryDialog({
    Key? key,
    required this.user,
  }) : super(key: key);

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return 'Permanent';

    final duration = end.difference(start);
    if (duration.inDays >= 30) {
      return '${(duration.inDays / 30).floor()} month(s)';
    } else if (duration.inDays >= 7) {
      return '${(duration.inDays / 7).floor()} week(s)';
    } else {
      return '${duration.inDays} day(s)';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y h:mm a').format(date);
  }

  bool _isBanActive(BanRecord ban) {
    if (!ban.isActive) return false;
    if (ban.endDate == null)
      return true; // Permanent ban is always active if not explicitly deactivated
    return ban.endDate!.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2F1552),
      title: Text(
        '${user.username}\'s Ban History',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: user.banHistory.length,
          itemBuilder: (context, index) {
            final ban = user.banHistory[index];
            final isActive = _isBanActive(ban);

            return Card(
              color: const Color(0xFF180B2D),
              child: ListTile(
                title: Text(
                  ban.reason,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start: ${_formatDate(ban.startDate)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (ban.endDate != null)
                      Text(
                        'End: ${_formatDate(ban.endDate!)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    Text(
                      'Duration: ${_formatDuration(ban.startDate, ban.endDate)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Status: ${isActive ? 'Active' : 'Expired'}',
                      style: TextStyle(
                        color: isActive ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
