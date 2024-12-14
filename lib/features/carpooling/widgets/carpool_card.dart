import 'package:capstone/core/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/carpooling/models/carpool_model.dart';
import 'package:capstone/core/services/firebase_service.dart';

class CarpoolCard extends StatelessWidget {
  final Carpool carpool;
  final VoidCallback onJoin;
  final String concertId; // Add this
  final FirebaseService _firebaseService = FirebaseService();

  CarpoolCard({
    Key? key,
    required this.carpool,
    required this.onJoin,
    required this.concertId,
  }) : super(key: key);

  Future<void> _showDeleteDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2F1552),
          title: Text('Delete Carpool', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete this carpool? This will delete the carpool chat as well.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await _firebaseService.deleteCarpool(
                    concertId,
                    carpool.id,
                    carpool.chatRoomId,
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _firebaseService.userAdminStream(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;

        return Stack(
          children: [
            Card(
              color: Color(0xFF3A215F),
              margin: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      top: 8.0,
                      bottom: 4.0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: Image.network(
                        carpool.imageUrl,
                        fit: BoxFit.cover,
                        height: 200, // Fixed height to match group card
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: const Color(0xFF2F1552),
                            child: const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: const Color(0xFF2F1552),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carpool.carpoolTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(carpool.driverId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData)
                                  return const SizedBox.shrink();

                                final userData = snapshot.data?.data()
                                    as Map<String, dynamic>?;
                                final totalRatings =
                                    userData?['totalCarpoolRatings'] ?? 0;
                                final ratings =
                                    userData?['carpoolRatings'] ?? 0.0;
                                final averageRating = totalRatings > 0
                                    ? ratings / totalRatings
                                    : 0.0;

                                return totalRatings > 0
                                    ? Row(
                                        children: [
                                          Icon(Icons.star,
                                              size: 16, color: Colors.amber),
                                          Text(
                                            ' ${averageRating.toStringAsFixed(1)} ($totalRatings)',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'No ratings yet',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                      );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildInfoRow(
                                      Icons.location_on,
                                      carpool.meetupLocation.startsWith('Starting')
                                          ? carpool.meetupLocation
                                          : carpool.meetupLocation),
                                  _buildInfoRow(Icons.people, carpool.slot),
                                  SizedBox(height: 4),
                                  _buildInfoRow(Icons.money, carpool.fee),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: SizedBox(
                                height: 50,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    side: BorderSide(
                                      width: 2.0,
                                      color: AppColors.borderColor,
                                    ),
                                    backgroundColor: const Color(0xFF2F1552),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () async {
                                    // Check if current user is the owner or already a passenger
                                    bool isOwner =
                                        _firebaseService.currentUser?.uid ==
                                            carpool.driverId;
                                    bool isPassenger = carpool.passengers
                                        .contains(
                                            _firebaseService.currentUser?.uid);

                                    // Allow access if owner, passenger, or if slots are available
                                    if (isOwner ||
                                        isPassenger ||
                                        carpool.availableSlots > 0) {
                                      try {
                                        // Only try to join if not owner and not already a passenger
                                        if (!isOwner && !isPassenger) {
                                          await _firebaseService.joinCarpool(
                                              carpool.chatRoomId, concertId);
                                        }
                                        onJoin();
                                      } catch (e) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor:
                                                const Color(0xFF2F1552),
                                            title: const Text(
                                              'Unable to Join',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            content: const Text(
                                              'Failed to join the carpool. If you are in an existing one, please leave first.',
                                              style: TextStyle(
                                                  color: Colors.white70),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text(
                                                  'OK',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    } else { // If users somehow still see the card even if its full
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor:
                                              const Color(0xFF2F1552),
                                          title: const Text(
                                            'Carpool Full',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          content: const Text(
                                            'Please check back later for available slots.',
                                            style: TextStyle(
                                                color: Colors.white70),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text(
                                                'OK',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Click to Join',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.iconColor,
          size: 14,
        ),
        SizedBox(width: 2),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontStyle: FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
