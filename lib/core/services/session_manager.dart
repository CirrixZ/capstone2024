import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  
  // Constants
  static const String _keyRememberMe = 'remember_me';
  static const String _keyLastEmail = 'last_email';
  static const String _keySessionExpiry = 'session_expiry';
  static const Duration _defaultSessionDuration = Duration(days: 30);
  
  // Rate limiting
  static const _maxVerificationAttempts = 3;
  static const _verificationCooldown = Duration(minutes: 5);
  
  final Map<String, int> _verificationAttempts = {};
  final Map<String, DateTime> _lastVerificationAttempt = {};

  factory SessionManager() {
    return _instance;
  }
  
  SessionManager._internal();

  // Remember Me functionality
  Future<void> setRememberMe(bool value, String email) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyRememberMe, value);
    if (value) {
      await prefs.setString(_keyLastEmail, email);
    } else {
      await prefs.remove(_keyLastEmail);
    }
  }

  Future<bool> getRememberMe() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  Future<String?> getLastEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLastEmail);
  }

  // Session Management
  Future<void> createSession(User user, {bool rememberMe = false}) async {
    final prefs = await _prefs;
    final now = DateTime.now();
    final expiryDate = now.add(
      rememberMe ? _defaultSessionDuration : const Duration(days: 1)
    );
    
    await prefs.setString(_keySessionExpiry, expiryDate.toIso8601String());
    
    // Store additional session data
    await prefs.setString('session_data', json.encode({
      'uid': user.uid,
      'email': user.email,
      'createdAt': now.toIso8601String(),
      'expiresAt': expiryDate.toIso8601String(),
    }));
  }

  Future<bool> isSessionValid() async {
    final prefs = await _prefs;
    final expiryString = prefs.getString(_keySessionExpiry);
    if (expiryString == null) return false;

    final expiry = DateTime.parse(expiryString);
    return DateTime.now().isBefore(expiry);
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_keySessionExpiry);
    await prefs.remove('session_data');
    await prefs.remove(_keyLastEmail);
    await prefs.remove(_keyRememberMe);
  }

  // Email verification rate limiting
  bool canSendVerificationEmail(String email) {
    final now = DateTime.now();
    final lastAttempt = _lastVerificationAttempt[email];
    final attempts = _verificationAttempts[email] ?? 0;

    if (lastAttempt != null) {
      final timeSinceLastAttempt = now.difference(lastAttempt);
      if (timeSinceLastAttempt < _verificationCooldown) {
        return false;
      }
      if (timeSinceLastAttempt > _verificationCooldown) {
        _verificationAttempts[email] = 0;
        return true;
      }
    }

    return attempts < _maxVerificationAttempts;
  }

  void recordVerificationAttempt(String email) {
    _verificationAttempts[email] = (_verificationAttempts[email] ?? 0) + 1;
    _lastVerificationAttempt[email] = DateTime.now();
  }

  Duration? getVerificationCooldownRemaining(String email) {
    final lastAttempt = _lastVerificationAttempt[email];
    if (lastAttempt == null) return null;

    final now = DateTime.now();
    final difference = _verificationCooldown - now.difference(lastAttempt);
    return difference.isNegative ? null : difference;
  }
}