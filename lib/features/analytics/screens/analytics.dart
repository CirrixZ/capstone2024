// lib/features/analytics/screens/analytics.dart

import 'package:flutter/material.dart';
import 'package:capstone/features/analytics/widgets/analytics_card.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/notifications/widgets/notification_badge.dart';

class AnalyticsPage extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();
  final String concertId;

  AnalyticsPage({
    super.key,
    required this.concertId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF180B2D),
        centerTitle: true,
        actions: [NotificationIconButton()],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _firebaseService.getConcertAnalytics(concertId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading analytics: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final analytics = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Concert Stats',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                AnalyticsCard(
                  title: 'Groups Created',
                  value: analytics['totalGroups'] ?? 0,
                  icon: Icons.group,
                  iconColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                AnalyticsCard(
                  title: 'Carpool Listings',
                  value: analytics['totalCarpools'] ?? 0,
                  icon: Icons.directions_car,
                  iconColor: Colors.green,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}