import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/core/services/session_manager.dart';

class EmailVerificationHandler {
  final FirebaseService _firebaseService;
  final SessionManager _sessionManager;
  
  EmailVerificationHandler({
    FirebaseService? firebaseService,
    SessionManager? sessionManager,
  }) : _firebaseService = firebaseService ?? FirebaseService(),
       _sessionManager = sessionManager ?? SessionManager();

  Future<(bool, String?)> sendVerificationEmail(String email) async {
    if (!_sessionManager.canSendVerificationEmail(email)) {
      final cooldown = _sessionManager.getVerificationCooldownRemaining(email);
      if (cooldown != null) {
        return (false, 'Please wait ${cooldown.inMinutes} minutes before requesting another verification email');
      }
      return (false, 'Too many attempts. Please try again later');
    }

    try {
      await _firebaseService.sendEmailVerification();
      _sessionManager.recordVerificationAttempt(email);
      return (true, null);
    } catch (e) {
      return (false, 'Failed to send verification email: ${e.toString()}');
    }
  }

  String? getVerificationMessage(String email) {
    final cooldown = _sessionManager.getVerificationCooldownRemaining(email);
    if (cooldown != null) {
      return 'Please wait ${cooldown.inMinutes} minutes before requesting another verification email';
    }
    return null;
  }
}