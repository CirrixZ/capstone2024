import 'package:capstone/features/auth/screens/login_or_register.dart';
import 'package:capstone/features/concerts/screens/concert_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  print("Waiting for user data...");
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const Center(
                    child: Text('Creating account...', 
                      style: TextStyle(color: Colors.white)
                    ),
                  );
                }

                return const ConcertList();
              },
            );
          } else {
            return const LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}