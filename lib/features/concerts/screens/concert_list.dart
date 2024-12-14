import 'package:capstone/features/auth/components/ban_check.dart';
import 'package:capstone/core/components/bottom_navbar.dart';
import 'package:capstone/features/concerts/models/concert_model.dart';
import 'package:capstone/features/concerts/widgets/concert_list_card.dart';
import 'package:capstone/features/notifications/widgets/notification_badge.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/components/nav_bar.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/concerts/screens/add_concert_screen.dart';

class ConcertList extends StatefulWidget {
  const ConcertList({super.key});

  @override
  ConcertListState createState() => ConcertListState();
}

class ConcertListState extends State<ConcertList> {
  final FirebaseService _firebaseService = FirebaseService();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      Map<String, dynamic> userProfile =
          await _firebaseService.getUserProfile();
      setState(() {
        _userName = '${userProfile['firstName']} ${userProfile['lastName']}';
      });
    } catch (e) {
      setState(() {
        _userName = 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BanCheck(
      child: Scaffold(
        drawer: NavBar(),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF180B2D),
          centerTitle: true,
          actions: <Widget>[
            NotificationIconButton(),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Welcome to Concert Page',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _userName.isNotEmpty ? '$_userName!' : 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<Concert>>(
                  stream: _firebaseService.getConcerts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No concerts available.'));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        Concert concert = snapshot.data![index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ConcertCard(
                            concert: concert,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BottomNavBar(concertId: concert.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: StreamBuilder<bool>(
          stream: _firebaseService
              .userAdminStream(), // Use the stream instead of future
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return FloatingActionButton(
                backgroundColor: Color(0xFF7000FF),
                child: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddConcertScreen()),
                  );
                },
              );
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
