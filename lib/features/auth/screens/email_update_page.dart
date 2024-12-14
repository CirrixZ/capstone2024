import 'package:flutter/material.dart';
import 'package:capstone/core/components/my_textfield.dart';
import 'package:capstone/core/services/firebase_service.dart';

class EmailUpdatePage extends StatefulWidget {
  const EmailUpdatePage({super.key});

  @override
  State<EmailUpdatePage> createState() => _EmailUpdatePageState();
}

class _EmailUpdatePageState extends State<EmailUpdatePage> {
  final newEmailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String? _errorMessage;
  bool _emailSent = false;

  Future<void> _updateEmail() async {
    try {
      await _firebaseService.updateEmail(
        newEmailController.text,
        passwordController.text,
      );
      setState(() {
        _emailSent = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _emailSent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/spage.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_emailSent) ...[
                Center(
                    child: const Text(
                  'Update Email',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                )),
                const SizedBox(height: 20),
                const Text(
                  'Enter your new email address and current password',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                MyTextField(
                  controller: newEmailController,
                  hintText: 'New Email',
                  obscureText: false,
                ),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Current Password',
                  obscureText: true,
                ),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7000FF),
                  ),
                  child: const Text(
                    'Update Email',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 20),
                const Text(
                  'A confirmation email has been sent to your new email address.\nYour email will be updated once you verify it through the link.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7000FF),
                  ),
                  child: const Text(
                    'Back to Profile',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF7000FF)
                        .withOpacity(0.5), // Semi-transparent warning color
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFF2F1552), width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFF7000FF),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Please re-sign in after verification to update email displayed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
