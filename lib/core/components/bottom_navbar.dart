import 'package:capstone/features/carpooling/screens/carpool_list.dart';
import 'package:capstone/features/concerts/screens/concert_details.dart';
import 'package:capstone/features/notifications/widgets/notification_badge.dart';
import 'package:capstone/features/verification/widgets/verification_gateway.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/components/nav_bar.dart';
import 'package:capstone/features/group_list/screens/group_list.dart';
import 'package:capstone/features/ticket_market/screens/ticket_market.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavBar extends StatefulWidget {
  final String concertId;
  final int initialIndex;

  const BottomNavBar({
    super.key,
    required this.concertId,
    this.initialIndex = 0,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _index;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _firebaseService.userAdminStream(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;
        return _buildMainScaffold(isAdmin: isAdmin);
      },
    );
  }

  Widget _buildMainScaffold({required bool isAdmin}) {
    final pages = [
      ConcertDetailsPage(
        isAdmin: isAdmin,
        concertId: widget.concertId,
      ),
      _wrapWithVerificationGateway(
        GroupList(
          isAdmin: isAdmin,
          concertId: widget.concertId,
        ),
      ),
      _wrapWithVerificationGateway(
        CarpoolList(concertId: widget.concertId),
      ),
      TicketMarketPage(concertId: widget.concertId),
    ];

    return Scaffold(
      drawer: NavBar(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF180B2D),
        centerTitle: true,
        actions: <Widget>[
          NotificationIconButton(),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF180B2D),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 200),
              tabBackgroundColor: const Color(0xFF8642F4),
              color: Colors.grey[400]!,
              tabs: const [
                GButton(
                  icon: Icons.groups_rounded,
                  text: 'Details',
                ),
                GButton(
                  icon: Icons.group,
                  text: 'Groups',
                ),
                GButton(
                  icon: Icons.directions_car,
                  text: 'Carpools',
                ),
                GButton(
                  icon: Icons.confirmation_number,
                  text: 'Tickets',
                ),
              ],
              selectedIndex: _index,
              onTabChange: (index) {
                setState(() {
                  _index = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _wrapWithVerificationGateway(Widget child) {
    return VerificationGateway(
      concertId: widget.concertId,
      child: child,
    );
  }
}
