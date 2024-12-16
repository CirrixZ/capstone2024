import 'package:capstone/core/components/my_button.dart';
import 'package:capstone/core/components/my_textfield.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/notifications/widgets/notification_intro_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();

  bool _isUsernameAvailable = true;
  String _usernameErrorText = '';
  bool _isLoading = false;

  // Name validation
  String? _firstNameErrorText;
  String? _lastNameErrorText;

  // Validation for names (only letters, spaces, and hyphens)
  bool isValidName(String name) {
    final RegExp nameRegex = RegExp(r'^[a-zA-Z\s-]+$');
    return nameRegex.hasMatch(name);
  }

  // Validate first name and last name
  String? validateName(String name, String nameType) {
    if (name.isEmpty) {
      return '$nameType name cannot be empty';
    } else if (name.length < 2) {
      return '$nameType name must be at least 2 characters';
    } else if (name.length > 30) {
      return '$nameType name must be at most 30 characters';
    } else if (!isValidName(name)) {
      return 'Only letters, spaces, and hyphens are allowed';
    }
    return null;
  }

  void validateFirstName(String firstName) {
    setState(() {
      _firstNameErrorText = validateName(firstName, 'First');
    });
  }

  void validateLastName(String lastName) {
    setState(() {
      _lastNameErrorText = validateName(lastName, 'Last');
    });
  }

  bool isValidUsername(String username) {
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    return usernameRegex.hasMatch(username);
  }

  // Function to check username requirements if it fits
  Future<void> checkUsername(String username) async {
    if (!mounted) return;

    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameErrorText = 'Username must be at least 3 characters long';
      });
      return;
    }
    if (username.length > 20) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameErrorText = 'Username must be at most 20 characters long';
      });
      return;
    }
    if (!isValidUsername(username)) {
      setState(() {
        _isUsernameAvailable = false;
        _usernameErrorText =
            'Username can only contain letters, numbers, and underscores';
      });
      return;
    }

    // Checks if username is still available
    bool isAvailable = await _firebaseService.isUsernameAvailable(username);
    if (!mounted) return;

    setState(() {
      _isUsernameAvailable = isAvailable;
      _usernameErrorText = isAvailable ? '' : 'Username is already taken';
    });
  }

  Future<void> signUserUp() async {
    // Validate all fields before submission
    validateFirstName(firstNameController.text);
    validateLastName(lastNameController.text);

    if (!context.mounted) return;

    // Check for any validation errors
    if (_firstNameErrorText != null ||
        _lastNameErrorText != null ||
        !_isUsernameAvailable) {
      if (_firstNameErrorText != null) {
        await showErrorDialog(_firstNameErrorText!);
      } else if (_lastNameErrorText != null) {
        await showErrorDialog(_lastNameErrorText!);
      } else {
        await showErrorDialog(_usernameErrorText);
      }
      return;
    }

    // Show error if password and confirm password don't match
    try {
      if (passwordController.text != confirmPasswordController.text) {
        await showErrorDialog("Passwords don't match!");
        return;
      }

      setState(() => _isLoading = true);

      // Show dialog and get settings
      final Map<String, dynamic>? notificationSettings = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const NotificationIntroDialog(),
      );

      if (notificationSettings == null) return; // User cancelled

      // Sign up user
      UserCredential credential = await _firebaseService.signUp(
        emailController.text,
        passwordController.text,
      );

      // Make sure we have a user ID
      if (credential.user?.uid == null) {
        throw Exception('Failed to create user account');
      }

      // Create user document to firebase with chosen notification settings
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'username': usernameController.text,
        'email': emailController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsernameChange': FieldValue.serverTimestamp(),
        'isAdmin': false,
        'isBanned': false,
        'emailVerified': false,
        'banHistory': [],
        'currentBanEnd': null,
        'notificationSettings': notificationSettings, // Use the chosen settings
      });
    } catch (e) {
      if (!context.mounted) return;
      await showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Show dialog if any errors happen(requirements not met)
  Future<void> showErrorDialog(String message) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.deepPurple,
        title: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/spage.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    "Let's create an account for you!",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 25),
                  MyTextField(
                    controller: firstNameController,
                    hintText: 'First Name',
                    obscureText: false,
                    onChanged: validateFirstName,
                    errorText: _firstNameErrorText,
                  ),
                  MyTextField(
                    controller: lastNameController,
                    hintText: 'Last Name',
                    obscureText: false,
                    onChanged: validateLastName,
                    errorText: _lastNameErrorText,
                  ),
                  MyTextField(
                    controller: usernameController,
                    hintText: 'Username',
                    obscureText: false,
                    onChanged: checkUsername,
                    errorText: _isUsernameAvailable ? null : _usernameErrorText,
                  ),
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  MyTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 25),
                  _isLoading // Put loading circle inside sign up button
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF7000FF)),
                        )
                      : AuthButton(
                          text: "Sign Up",
                          onTap: signUserUp,
                        ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Login now',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
