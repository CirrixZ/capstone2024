import 'package:capstone/core/helpers/custom_page_transitions.dart';
import 'package:capstone/features/auth/screens/auth_page.dart';
import 'package:capstone/features/concerts/screens/concert_list.dart';
import 'package:capstone/features/messages/screens/messages_page.dart';
import 'package:capstone/features/profile/screens/profile.dart';
import 'package:capstone/features/users/screens/users_page.dart';
import 'package:capstone/features/verification/screens/ticket_approvals_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:flutter/services.dart';

class NavBar extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  NavBar({super.key});

  void signUserOut(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    _firebaseService.signOut().then((_) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss the progress dialog
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (Route<dynamic> route) => false,
        );
      }
    }).catchError((error) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss the progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // Method to show contact dialog
  void _showContactDialog(BuildContext context) {
    final String contactEmail = 'ninevehgroupp@gmail.com';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E0F60),
          title: const Text(
            'Contact Us',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To apply for admin or for other inquiries, email us at:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                contactEmail,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: contactEmail));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email copied to clipboard'),
                    backgroundColor: Color(0xFF7000FF),
                  ),
                );
              },
              child: const Text(
                'Copy Email',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;
    const drawerColor = Color(0xFF2E0F60);

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Drawer(
      child: Container(
        color: drawerColor,
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  return UserAccountsDrawerHeader(
                    // User profile picture
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: userData?['profilePicture'] != null
                          ? NetworkImage(userData!['profilePicture'])
                          : null,
                      child: userData?['profilePicture'] == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: drawerColor,
                            )
                          : null,
                    ),
                    accountName: Text(
                      userData?['username'] ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    accountEmail: Text(
                      user.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    decoration: const BoxDecoration(
                      color: drawerColor,
                    ),
                  );
                }
                return const UserAccountsDrawerHeader(
                  accountName: Text('Loading...'),
                  accountEmail: Text(''),
                  decoration: BoxDecoration(color: drawerColor),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                AppPageRoute(page: const ConcertList()),
                (route) => false,
              ),
            ),
            _buildNavItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () => Navigator.push(
                context,
                AppPageRoute(page: const ProfilePage()),
              ),
            ),
            StreamBuilder<bool>(
              stream: _firebaseService.hasUnreadMessages(),
              builder: (context, snapshot) {
                return _buildNavItem(
                  icon: Icons.mail,
                  title: 'Messages',
                  showUnreadIndicator: snapshot.data ?? false,
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute(page: const MessagesPage()),
                  ),
                );
              },
            ),
            StreamBuilder<bool>(
              stream: _firebaseService.userAdminStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return _buildNavItem(
                    icon: Icons.people_outlined,
                    title: 'Users',
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(page: UsersPage()),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            StreamBuilder<bool>(
              stream: _firebaseService.userAdminStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return _buildNavItem(
                    icon: Icons.verified_user,
                    title: 'Ticket Approvals',
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(page: TicketApprovalsPage()),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Spacer(),
            StreamBuilder<bool>(
              stream: _firebaseService.userStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return _buildNavItem(
                    icon: Icons.contact_support,
                    title: 'Contact Us',
                    onTap: () => _showContactDialog(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            _buildNavItem(
              icon: Icons.logout_outlined,
              title: 'Log Out',
              onTap: () => signUserOut(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Styling of each nav bar item
  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showUnreadIndicator = false,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(icon, color: Colors.white),
          if (showUnreadIndicator)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF7000FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}
