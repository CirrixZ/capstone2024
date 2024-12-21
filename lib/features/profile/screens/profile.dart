import 'dart:io';
import 'package:capstone/core/components/custom_dialog.dart';
import 'package:capstone/core/components/image_picker_utils.dart';
import 'package:capstone/core/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/components/my_textfield.dart';
import 'package:capstone/core/services/firebase_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool isEditMode = false;
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();

  String? _usernameErrorText;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Reloads the user to get latest verification status
      await FirebaseAuth.instance.currentUser?.reload();

      // Gets the profile details of the user
      Map<String, dynamic> userProfile =
          await _firebaseService.getUserProfile();

      // Check if email needs verification
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        // Optionally show a snackbar prompting verification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please verify your email address'),
              action: SnackBarAction(
                label: 'Send Email',
                onPressed: () => _firebaseService.sendEmailVerification(),
              ),
            ),
          );
        }
      }

      setState(() {
        firstNameController.text = userProfile['firstName'] ?? '';
        lastNameController.text = userProfile['lastName'] ?? '';
        usernameController.text = userProfile['username'] ?? '';
        _profileImageUrl = userProfile['profilePicture'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      final File? image = await ImagePickerUtil.pickAndCropProfileImage(
          context); // Changed this line
      if (image != null) {
        await _firebaseService.updateProfilePicture(image.path);
        await _loadUserProfile(); // Reload profile to get new image URL
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    try {
      await _firebaseService.updateUserProfile(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        username: usernameController.text,
        newPassword: newPasswordController.text.isNotEmpty
            ? newPasswordController.text
            : null,
        currentPassword: currentPasswordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      setState(() {
        isEditMode = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  void _checkUsername(String username) async {
    if (username != usernameController.text) {
      bool isAvailable = await _firebaseService.isUsernameAvailable(username);
      setState(() {
        _usernameErrorText = isAvailable ? null : 'Username is already taken';
      });
    } else {
      setState(() {
        _usernameErrorText = null;
      });
    }
  }

  // Email change dialog
  void _showChangeEmailDialog() {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Change Email',
        fields: [
          CustomDialogField(
            label: 'New Email',
            hint: 'Enter your new email address',
            keyboardType: TextInputType.emailAddress,
            controller: newEmailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email address';
              }
              if (value == FirebaseAuth.instance.currentUser?.email) {
                return 'New email must be different from current email';
              }
              return null;
            },
          ),
          CustomDialogField(
            label: 'Current Password',
            hint: 'Enter your current password',
            controller: passwordController,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
        ],
        submitButtonText: 'Update Email',
        onSubmit: (values, _) async {
          await _firebaseService.updateEmail(
            values['New Email']!,
            values['Current Password']!,
          );

          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Verification email sent! Please verify your new email address and reopen this page to see changes.',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Delete account dialog
  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: 'Delete Account',
          fields: [
            CustomDialogField(
              label: 'Password',
              hint: 'Enter your password to confirm',
              controller: passwordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
          ],
          submitButtonText: 'Delete Account',
          customWidget: const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          onSubmit: (values, _) async {
            try {
              // Show confirmation dialog
              bool? confirmDelete = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => AlertDialog(
                  title: const Text(
                    'Confirm Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Color(0xFF2F1552),
                  content: const Text(
                    'Are you sure you want to delete your account? This action cannot be undone.',
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true) {
                // Delete the account
                await _firebaseService.deleteUserAccount(values['Password']!);

                // Close the delete account dialog
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            } catch (e) {
              return Future.error(e.toString());
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF180B2D),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickProfilePicture,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.buttonColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${firstNameController.text} ${lastNameController.text}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                Text(
                  usernameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Email Verification Status (moved outside the Stack)
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final isVerified = snapshot.data!.emailVerified;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isVerified
                                    ? Icons.verified_user
                                    : Icons.warning,
                                color:
                                    isVerified ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isVerified
                                    ? 'Email Verified'
                                    : 'Email Not Verified',
                                style: TextStyle(
                                  color:
                                      isVerified ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          if (!isVerified)
                            TextButton(
                              onPressed: () async {
                                try {
                                  await _firebaseService
                                      .sendEmailVerification();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Verification email sent! Please reopen this page after you verify your account to see changes.'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Error: ${e.toString()}')),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'Send Verification Email',
                                style: TextStyle(color: Color(0xFF7000FF)),
                              ),
                            ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.email, color: Colors.white70),
                  label: const Text('Change Email',
                      style: TextStyle(color: Colors.white70)),
                  onPressed: _showChangeEmailDialog,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: _showDeleteAccountDialog,
                ),
                SizedBox(
                  width: 170,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isEditMode = !isEditMode;
                      });
                    },
                    child: Text(
                      isEditMode ? 'Cancel' : 'Edit Profile Info',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 16.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (isEditMode) ...[
                  SizedBox(height: 8),
                  Text(
                    'Tap your profile picture to change it',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: MyTextField(
                                controller: firstNameController,
                                hintText: 'First Name',
                                obscureText: false,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MyTextField(
                                controller: lastNameController,
                                hintText: 'Last Name',
                                obscureText: false,
                              ),
                            ),
                          ],
                        ),
                        MyTextField(
                          controller: usernameController,
                          hintText: 'Username',
                          obscureText: false,
                          onChanged: _checkUsername,
                          errorText: _usernameErrorText,
                        ),
                        const SizedBox(height: 10),
                        const Text("To confirm any of these changes:",
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                        MyTextField(
                          controller: currentPasswordController,
                          hintText: 'Current Password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        const Text("Change Password:",
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                        MyTextField(
                          controller: newPasswordController,
                          hintText: 'New Password',
                          obscureText: true,
                        ),
                        MyTextField(
                          controller: confirmPasswordController,
                          hintText: 'Confirm Password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 160,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: _updateProfile,
                            child: const Text(
                              'Apply Changes',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 16.0),
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
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    currentPasswordController.dispose();
    super.dispose();
  }
}
