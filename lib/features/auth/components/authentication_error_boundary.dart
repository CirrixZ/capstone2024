import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone/core/constants/colors.dart';

class AuthErrorBoundary extends StatelessWidget {
  final Widget child;
  final Function()? onRetry;
  final Function(FirebaseAuthException)? onAuthError;

  const AuthErrorBoundary({
    super.key,
    required this.child,
    this.onRetry,
    this.onAuthError,
  });

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password';
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'user-banned':
        return e.message ?? 'Your account has been suspended';
      default:
        return e.message ?? 'An unknown error occurred';
    }
  }

  Widget _buildErrorWidget(BuildContext context, FirebaseAuthException error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _getAuthErrorMessage(error),
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError && snapshot.error is FirebaseAuthException) {
          final error = snapshot.error as FirebaseAuthException;
          onAuthError?.call(error);
          return _buildErrorWidget(context, error);
        }
        return child;
      },
    );
  }
}