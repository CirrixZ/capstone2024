import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/verification/widgets/ticket_verification_dialog.dart';

class VerificationGateway extends StatelessWidget {
  final String concertId;
  final Widget child;
  final FirebaseService _firebaseService = FirebaseService();

  VerificationGateway({
    super.key,
    required this.concertId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _firebaseService.checkVerificationStatus(concertId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7000FF)),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user,
                  size: 64,
                  color: Colors.white70,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ticket Verification Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please verify your ticket to access concert features',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7000FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () => _showVerificationDialog(context),
                  child: const Text(
                    'Verify Ticket',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => TicketVerificationDialog(
        onSubmit: (image) async {
          await _firebaseService.submitTicketVerification(
            concertId,
            image,
          );

          // Use the root navigator to show SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification submitted successfully'),
              backgroundColor: Color(0xFF7000FF),
            ),
          );

          // Close the dialog
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
}
