import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:capstone/core/services/firebase_service.dart';

class NotificationSettingsPage extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings', 
          style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF180B2D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _firebaseService.getUserNotificationSettings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data ?? {
            'ticketUpdates': true,
            'groupMessages': true,
            'carpoolMessages': true,
            'concertUpdates': true,
            'soundEnabled': true,
            'vibrationEnabled': true,
          };

          return ListView(
            children: [
              _buildSection(
                title: 'Notification Types',
                children: [
                  _buildSettingTile(
                    context: context,
                    title: 'Concert Updates',
                    subtitle: 'Changes to concert details and schedules',
                    value: settings['concertUpdates'] ?? true,
                    onChanged: (value) => _updateSetting('concertUpdates', value),
                    icon: Icons.event,
                  ),
                  _buildSettingTile(
                    context: context,
                    title: 'Ticket Updates',
                    subtitle: 'New tickets and availability changes',
                    value: settings['ticketUpdates'] ?? true,
                    onChanged: (value) => _updateSetting('ticketUpdates', value),
                    icon: Icons.confirmation_number,
                  ),
                  _buildSettingTile(
                    context: context,
                    title: 'Group Messages',
                    subtitle: 'Messages from group chats',
                    value: settings['groupMessages'] ?? true,
                    onChanged: (value) => _updateSetting('groupMessages', value),
                    icon: Icons.group,
                  ),
                  _buildSettingTile(
                    context: context,
                    title: 'Carpool Messages',
                    subtitle: 'Messages from carpool chats',
                    value: settings['carpoolMessages'] ?? true,
                    onChanged: (value) => _updateSetting('carpoolMessages', value),
                    icon: Icons.directions_car,
                  ),
                ],
              ),
              _buildSection(
                title: 'Alert Settings',
                children: [
                  _buildSettingTile(
                    context: context,
                    title: 'Sound',
                    subtitle: 'Play sound for notifications',
                    value: settings['soundEnabled'] ?? true,
                    onChanged: (value) {
                      _updateSetting('soundEnabled', value);
                      if (value) {
                        // Play test sound
                        SystemSound.play(SystemSoundType.alert);
                      }
                    },
                    icon: Icons.volume_up,
                  ),
                  _buildSettingTile(
                    context: context,
                    title: 'Vibration',
                    subtitle: 'Vibrate for notifications',
                    value: settings['vibrationEnabled'] ?? true,
                    onChanged: (value) {
                      _updateSetting('vibrationEnabled', value);
                      if (value) {
                        // Test vibration
                        HapticFeedback.mediumImpact();
                      }
                    },
                    icon: Icons.vibration,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2F1552),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF7000FF),
        ),
      ),
    );
  }

  void _updateSetting(String setting, bool value) {
    _firebaseService.updateNotificationSetting(setting, value);
  }
}