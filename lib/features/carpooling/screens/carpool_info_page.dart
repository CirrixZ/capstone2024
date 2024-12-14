import 'package:capstone/features/carpooling/widgets/rating_dialog.dart';
import 'package:capstone/features/users/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/carpooling/widgets/meetup_card.dart';
import 'package:capstone/features/carpooling/widgets/members_section.dart';

class CarpoolInfoPage extends StatefulWidget {
  final String chatRoomId;
  final String concertId;
  final bool isDriver;

  const CarpoolInfoPage({
    super.key,
    required this.chatRoomId,
    required this.concertId,
    required this.isDriver,
  });

  @override
  State<CarpoolInfoPage> createState() => _CarpoolInfoPageState();
}

class _CarpoolInfoPageState extends State<CarpoolInfoPage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  Future<void> _updateRsvp(String status) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _firebaseService.updateCarpoolRsvp(
        widget.chatRoomId,
        status,
        widget.concertId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> onEditPressed(String location, DateTime time) async {
    await _firebaseService.updateCarpoolMeetup(
      widget.chatRoomId,
      widget.concertId,
      location,
      time,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carpool Details',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF180B2D),
        actions: [
          // Show delete button for driver
          if (widget.isDriver)
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF2F1552),
                    title: const Text(
                      'Delete Carpool',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to delete this carpool? This cannot be undone.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true) {
                  try {
                    await _firebaseService.deleteOwnCarpool(
                      widget.chatRoomId,
                      widget.concertId,
                    );
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Carpool deleted')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                }
              },
            ),
          // Show leave button for non-driver members
          if (!widget.isDriver)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              color: Colors.red,
              onPressed: () async {
                final shouldLeave = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF2F1552),
                    title: const Text(
                      'Leave Carpool',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to leave this carpool? You won\'t be able to rejoin later.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Leave',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldLeave == true) {
                  try {
                    await _firebaseService.leaveCarpool(
                      widget.chatRoomId,
                      widget.concertId,
                    );
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('You have left the carpool')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        // Update stream to include concertId
        stream: _firebaseService.getCarpoolInfo(
            widget.chatRoomId, widget.concertId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final carpoolData = snapshot.data ?? {};
          // Get RSVP status from carpool document now
          final userRsvp = carpoolData['rsvpStatus']
                  ?[_firebaseService.currentUser?.uid] ??
              'pending';
          final driverRating = (carpoolData['driverRating'] ?? 0.0).toDouble();
          final totalRatings = carpoolData['totalRatings'] ?? 0;

          // Show rating dialog if needed
          if (!widget.isDriver &&
              carpoolData['status'] == 'CarpoolStatus.completed' &&
              (carpoolData['ratedBy'] == null ||
                  !(carpoolData['ratedBy'] as List<dynamic>)
                      .contains(_firebaseService.currentUser?.uid))) {
            bool dialogShown = false;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!dialogShown) {
                dialogShown = true;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => RatingDialog(
                    carpoolId: widget.chatRoomId,
                    driverName: carpoolData['driverName'] ?? 'Driver',
                    onSubmit: (rating, comment) async {
                      try {
                        await _firebaseService.submitRating(
                          widget.concertId,
                          widget.chatRoomId,
                          rating,
                          comment: comment,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Rating submitted successfully')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error submitting rating: $e')),
                          );
                        }
                      }
                    },
                  ),
                );
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (totalRatings > 0)
                  Card(
                    color: const Color(0xFF2F1552),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Text(
                            ' ${driverRating.toStringAsFixed(1)} (${totalRatings} ratings)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                MeetupCard(
                  carpoolData: carpoolData,
                  isDriver: widget.isDriver,
                  isLoading: _isLoading,
                  userRsvp: userRsvp,
                  concertId: widget.concertId,
                  onEditPressed: onEditPressed,
                  onRsvp: _updateRsvp,
                  onComplete: (carpoolId) async {
                    try {
                      await _firebaseService.markCarpoolComplete(carpoolId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Carpool marked as complete')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),
                StreamBuilder<List<UserModel>>(
                  // Keep using getChatRoomMembers for now since we still need chat functionality
                  stream:
                      _firebaseService.getChatRoomMembers(widget.chatRoomId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return MembersSection(
                      members: snapshot.data!,
                      carpoolData: carpoolData,
                      isDriver: widget.isDriver,
                      carpoolId: widget.chatRoomId,
                      concertId: widget.concertId,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
