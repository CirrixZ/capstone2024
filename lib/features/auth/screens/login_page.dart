import 'package:capstone/core/components/my_button.dart';
import 'package:capstone/core/services/session_manager.dart';
import 'package:capstone/core/components/my_textfield.dart';
import 'package:capstone/core/constants/colors.dart';
import 'package:capstone/core/helpers/custom_page_transitions.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/auth/components/authentication_error_boundary.dart';
import 'package:capstone/features/auth/screens/password_reset_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final SessionManager _sessionManager = SessionManager();
  bool _isAdminLogin = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void toggleLoginMode() {
    setState(() {
      _isAdminLogin = !_isAdminLogin;
    });
  }

  Future<void> _loadSavedEmail() async {
    final rememberMe = await _sessionManager.getRememberMe();
    if (rememberMe) {
      final savedEmail = await _sessionManager.getLastEmail();
      if (savedEmail != null) {
        setState(() {
          emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    }
  }

  // In LoginPage
  Future<void> signUserIn() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      if (_isAdminLogin) {
        await _firebaseService.signInAdmin(
          emailController.text,
          passwordController.text,
        );
      } else {
        await _firebaseService.signIn(
          emailController.text,
          passwordController.text,
        );
      }

      await _sessionManager.setRememberMe(_rememberMe, emailController.text);
      if (_rememberMe) {
        await _sessionManager.createSession(
          FirebaseAuth.instance.currentUser!,
          rememberMe: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'user-banned') {
        await _showBanDialog(e.message ?? 'Your account has been suspended');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.code)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-credential': // Add this case
        return 'Incorrect email or password';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'An error occurred. Please try again';
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    // Clear any existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3), // Make sure it shows long enough
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _showBanDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: const Text(
          'Account Suspended',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(color: AppColors.textWhite70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please contact support for more information.',
              style: TextStyle(color: AppColors.textWhite70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _firebaseService.signOut();
              Navigator.pop(context);
            },
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.borderColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthErrorBoundary(
      onRetry: _isLoading ? null : signUserIn,
      onAuthError: (e) => _showErrorSnackbar(_getErrorMessage(e.code)),
      child: Container(
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
                    const SizedBox(height: 20),
                    // Align the welcome text to the left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Welcome\nto\nMetaConcert", // Large text
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34, // Big font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Align the description text to the left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 250,
                        child: const Text(
                          "Unite with Music Lovers! Elevate your concert experience with our app’s interactive community, carpool listings, and seamless integrated ticket markets.",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.white70, // Smaller text color
                            fontSize: 12, // Smaller font size
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _isAdminLogin
                          ? 'Sign-in to your account'
                          : 'Sign-in to your account',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value!);
                                },
                                checkColor: Colors.white, // Color when checked
                                activeColor: AppColors
                                    .buttonColor, // Background when checked
                                side: BorderSide(
                                    color: AppColors
                                        .buttonColor), // Border color when unchecked
                              ),
                              const Text(
                                'Remember me',
                                style: TextStyle(color: AppColors.textWhite),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              AppPageRoute(page: const PasswordResetPage()),
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: AppColors.textWhite),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                    _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.buttonColor,
                            ),
                          )
                        : authButton(
                            text: _isAdminLogin
                                ? "Admin Sign In"
                                : "User Sign In",
                            onTap: signUserIn,
                          ),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: Incorrect login type will result in automatic sign out',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: toggleLoginMode,
                      child: Text(
                        _isAdminLogin
                            ? 'Switch to User Login'
                            : 'Switch to Admin Login',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_isAdminLogin) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Not a member?',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: widget.onTap,
                            child: const Text(
                              'Register now',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
