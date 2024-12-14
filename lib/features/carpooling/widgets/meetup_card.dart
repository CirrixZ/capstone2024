import 'package:capstone/core/components/custom_dialog.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:capstone/features/carpooling/widgets/rsvp_row.dart';

class MeetupCard extends StatelessWidget {
  final Map<String, dynamic> carpoolData;
  final bool isDriver;
  final bool isLoading;
  final String userRsvp;
  final String concertId;
  final Future<void> Function(String, DateTime) onEditPressed;
  final Function(String) onRsvp;
  final Future<void> Function(String)? onComplete;
  final FirebaseService _firebaseService = FirebaseService();

  MeetupCard({
    super.key,
    required this.carpoolData,
    required this.isDriver,
    required this.isLoading,
    required this.userRsvp,
    required this.concertId,
    required this.onEditPressed,
    required this.onRsvp,
    this.onComplete,
  });

  void _showMeetupEditDialog(BuildContext context) {
    final locationController = TextEditingController(
      text: carpoolData['meetupLocation'] ?? '',
    );
    DateTime selectedDateTime =
        carpoolData['meetupTime']?.toDate() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Edit Meetup Details',
        fields: [
          CustomDialogField(
            label: 'Location',
            hint: 'Enter meetup location',
            controller: locationController,
          ),
        ],
        customWidget: StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              ListTile(
                title: Text(
                  'Date & Time',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  DateFormat('MMM d, y - h:mm a').format(selectedDateTime),
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: Icon(Icons.calendar_today, color: Colors.white),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2025),
                    builder: (context, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: Color(0xFF6A00F4),
                          surface: Color(0xFF2F1552),
                        ),
                        dialogBackgroundColor: Color(0xFF2F1552),
                      ),
                      child: child!,
                    ),
                  );

                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: Color(0xFF6A00F4),
                            surface: Color(0xFF2F1552),
                          ),
                          dialogBackgroundColor: Color(0xFF2F1552),
                        ),
                        child: child!,
                      ),
                    );

                    if (pickedTime != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
        onSubmit: (values, _) async {
          await onEditPressed(locationController.text, selectedDateTime);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetupLocation = carpoolData['meetupLocation'];
    final meetupTime = carpoolData['meetupTime'] as Timestamp?;
    final status = carpoolData['status'] ?? 'CarpoolStatus.active';
    final isCompleted =
        status == 'CarpoolStatus.completed' || status == 'CarpoolStatus.rated';
    final bool allRated = carpoolData['ratedBy'] != null &&
        List<String>.from(carpoolData['ratedBy']).length ==
            List<String>.from(carpoolData['passengers'] ?? []).length;

    return Card(
      color: const Color(0xFF2F1552),
      child: Column(
        children: [
          // Show completion status banner if completed
          if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF7000FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Text(
                'Carpool Completed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Starting Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isDriver && !isCompleted)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: () => _showMeetupEditDialog(context),
                      ),
                  ],
                ),
                if (meetupLocation != null) ...[
                  Text(
                    meetupLocation,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (meetupTime != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Time: ${DateFormat('MMM d, y - h:mm a').format(meetupTime.toDate())}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  if (!isDriver && !isCompleted && meetupTime != null) ...[
                    const SizedBox(height: 16),
                    RsvpRow(
                      userRsvp: userRsvp,
                      isLoading: isLoading,
                      onRsvp: onRsvp,
                    ),
                  ],
                  // Modified completion/rating button section
                  if ((isDriver || // Show for driver
                          (!isDriver &&
                              status ==
                                  'CarpoolStatus.completed')) && // Show for passengers after completion
                      meetupTime != null &&
                      DateTime.now().isAfter(meetupTime.toDate())) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: isDriver
                          ? (allRated
                              ? const Text(
                                  'Rating Completed! You may now delete the carpool.',
                                  style: TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                )
                              : status == 'CarpoolStatus.completed'
                                  ? const Text(
                                      'Waiting for member reviews...',
                                      style: TextStyle(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF7000FF),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      onPressed: () => onComplete
                                          ?.call(carpoolData['chatRoomId']),
                                      child: const Text(
                                        'Mark Carpool as Complete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ))
                          : (carpoolData['ratedBy'] == null ||
                                  !List<String>.from(carpoolData['ratedBy'])
                                      .contains(
                                          _firebaseService.currentUser?.uid))
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7000FF),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  onPressed: () => onComplete
                                      ?.call(carpoolData['chatRoomId']),
                                  child: const Text(
                                    'Rate Carpool',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Thank you for your review!',
                                  style: TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                    ),
                  ],
                ] else
                  const Text(
                    'No meetup location set',
                    style: TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
