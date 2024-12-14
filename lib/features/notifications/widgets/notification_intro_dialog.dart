import 'package:flutter/material.dart';

class NotificationSettings {
  bool ticketUpdates;
  bool groupMessages;
  bool carpoolMessages;
  bool concertUpdates;
  bool soundEnabled;
  bool vibrationEnabled;

  NotificationSettings({
    this.ticketUpdates = true,
    this.groupMessages = true,
    this.carpoolMessages = true,
    this.concertUpdates = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketUpdates': ticketUpdates,
      'groupMessages': groupMessages,
      'carpoolMessages': carpoolMessages,
      'concertUpdates': concertUpdates,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }
}

class NotificationIntroDialog extends StatefulWidget {
  const NotificationIntroDialog({super.key});

  @override
  State<NotificationIntroDialog> createState() => _NotificationIntroDialogState();
}

class _NotificationIntroDialogState extends State<NotificationIntroDialog> {
  final NotificationSettings settings = NotificationSettings();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: const Color(0xFF2F1552),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose your notification preferences:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              NotificationSettingRow(
                icon: Icons.confirmation_number,
                text: 'Ticket Updates',
                value: settings.ticketUpdates,
                onChanged: (value) => setState(() => settings.ticketUpdates = value),
              ),
              NotificationSettingRow(
                icon: Icons.group,
                text: 'Group Messages',
                value: settings.groupMessages,
                onChanged: (value) => setState(() => settings.groupMessages = value),
              ),
              NotificationSettingRow(
                icon: Icons.directions_car,
                text: 'Carpool Updates',
                value: settings.carpoolMessages,
                onChanged: (value) => setState(() => settings.carpoolMessages = value),
              ),
              NotificationSettingRow(
                icon: Icons.event,
                text: 'Concert Updates',
                value: settings.concertUpdates,
                onChanged: (value) => setState(() => settings.concertUpdates = value),
              ),
              const Divider(color: Colors.white24),
              NotificationSettingRow(
                icon: Icons.volume_up,
                text: 'Sound',
                value: settings.soundEnabled,
                onChanged: (value) => setState(() => settings.soundEnabled = value),
              ),
              NotificationSettingRow(
                icon: Icons.vibration,
                text: 'Vibration',
                value: settings.vibrationEnabled,
                onChanged: (value) => setState(() => settings.vibrationEnabled = value),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can change these settings anytime in your profile.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(settings.toMap()),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF7000FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationSettingRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NotificationSettingRow({
    super.key,
    required this.icon,
    required this.text,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7000FF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7000FF),
          ),
        ],
      ),
    );
  }
}