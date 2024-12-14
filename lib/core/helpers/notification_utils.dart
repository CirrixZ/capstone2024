import 'package:flutter/services.dart';
import 'package:capstone/core/services/firebase_service.dart';

class NotificationUtils {
  static NotificationUtils? _instance;
  final FirebaseService _firebaseService = FirebaseService();

  NotificationUtils._();

  static NotificationUtils get instance {
    _instance ??= NotificationUtils._();
    return _instance!;
  }

  Future<void> playNotificationFeedback() async {
    final settings = await _firebaseService.getUserNotificationSettings().first;
    
    // Check sound setting
    if (settings['soundEnabled'] ?? true) {
      await SystemSound.play(SystemSoundType.alert);
    }
    
    // Check vibration setting
    if (settings['vibrationEnabled'] ?? true) {
      await HapticFeedback.mediumImpact();
    }
  }
}