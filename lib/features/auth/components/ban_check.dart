import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:intl/intl.dart';

class BanCheck extends StatelessWidget {
  final Widget child;
  final FirebaseService _firebaseService = FirebaseService();

  BanCheck({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firebaseService.currentUser != null
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(_firebaseService.currentUser!.uid)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.get('isBanned') == true) {
          final currentBanEnd =
              snapshot.data?.get('currentBanEnd') as Timestamp?;
          final banMessage = currentBanEnd != null
              ? 'Account suspended until ${DateFormat('MMM d, y h:mm a').format(currentBanEnd.toDate())}'
              : 'Your account has been permanently suspended';

          return Scaffold(
            backgroundColor: const Color(0xFF180B2D),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.block,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Account Suspended',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      banMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7000FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        await _firebaseService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/auth',
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
