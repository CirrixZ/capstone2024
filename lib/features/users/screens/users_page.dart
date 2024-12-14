import 'package:capstone/core/constants/colors.dart';
import 'package:capstone/features/users/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/users/models/user_model.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  UserFilter _currentFilter = UserFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    // First apply search filter
    var filteredUsers = users.where((user) {
      final searchLower = _searchQuery.toLowerCase();
      return user.username.toLowerCase().contains(searchLower) ||
          user.firstName.toLowerCase().contains(searchLower) ||
          user.lastName.toLowerCase().contains(searchLower);
    }).toList();

    // Then apply status filter
    switch (_currentFilter) {
      case UserFilter.admin:
        return filteredUsers.where((user) => user.isAdmin).toList();
      case UserFilter.banned:
        return filteredUsers.where((user) => user.isBanned).toList();
      case UserFilter.active:
        return filteredUsers.where((user) => !user.isBanned).toList();
      case UserFilter.all:
      default:
        return filteredUsers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF180B2D),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<UserFilter>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            color: const Color(0xFF2F1552),
            onSelected: (UserFilter filter) {
              setState(() => _currentFilter = filter);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: UserFilter.all,
                child: _buildFilterMenuItem(
                  'All Users',
                  Icons.people,
                  _currentFilter == UserFilter.all,
                ),
              ),
              PopupMenuItem(
                value: UserFilter.admin,
                child: _buildFilterMenuItem(
                  'Admins',
                  Icons.admin_panel_settings,
                  _currentFilter == UserFilter.admin,
                ),
              ),
              PopupMenuItem(
                value: UserFilter.banned,
                child: _buildFilterMenuItem(
                  'Banned Users',
                  Icons.block,
                  _currentFilter == UserFilter.banned,
                ),
              ),
              PopupMenuItem(
                value: UserFilter.active,
                child: _buildFilterMenuItem(
                  'Active Users',
                  Icons.check_circle,
                  _currentFilter == UserFilter.active,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
            'Users Management',
            style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2F1552),
                hintText: 'Search by name or username...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          StreamBuilder<List<UserModel>>(
            stream: _firebaseService.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF7000FF)),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Expanded(
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }

              final filteredUsers = _filterUsers(snapshot.data ?? []);

              if (filteredUsers.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No users found'
                          : 'No users match your search',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }

              return Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    return UserCard(user: filteredUsers[index]);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMenuItem(String text, IconData icon, bool isSelected) {
    return Row(
      children: [
        Icon(
          icon,
          color: isSelected ? const Color(0xFF7000FF) : Colors.white,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF7000FF) : Colors.white,
          ),
        ),
      ],
    );
  }
}

enum UserFilter {
  all,
  admin,
  banned,
  active,
}
