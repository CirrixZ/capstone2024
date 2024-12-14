import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/shared/widgets/member_card.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/users/models/user_model.dart';

class MembersSection extends StatelessWidget {
  final List<UserModel> members;
  final Map<String, dynamic> carpoolData;
  final bool isDriver; // Add this
  final String carpoolId; // Add this
  final String concertId; // Add this
  final FirebaseService _firebaseService = FirebaseService(); // Add this

  MembersSection({
    super.key,
    required this.members,
    required this.carpoolData,
    required this.isDriver, // Add this
    required this.carpoolId, // Add this
    required this.concertId, // Add this
  });

  @override
  Widget build(BuildContext context) {
    final String driverId = carpoolData['driverId'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Carpool Members',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...members.map(
          (user) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: MemberCard(
                user: user,
                rsvpStatus: carpoolData['rsvpStatus']?[user.id] ?? 'pending',
                isDriver: user.id == carpoolData['driverId'],
                canKick: isDriver && user.id != driverId,
                onKick: () => _firebaseService.kickFromCarpool(
                    carpoolId, user.id, concertId),
              )),
        ),
      ],
    );
  }
}
