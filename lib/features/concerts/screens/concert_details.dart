import 'package:capstone/core/constants/colors.dart';
import 'package:capstone/features/concerts/helpers/concert_dialog_helpers.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/concerts/models/concert_model.dart';
import 'package:capstone/features/concerts/widgets/concert_details_card.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class ConcertDetailsPage extends StatelessWidget {
  final bool isAdmin;
  final String concertId;
  final FirebaseService _firebaseService = FirebaseService();
  late final ConcertDialogHelpers _dialogHelpers;

  ConcertDetailsPage({
    super.key,
    required this.isAdmin,
    required this.concertId,
  }) {
    _dialogHelpers = ConcertDialogHelpers(_firebaseService);
  }

  SpeedDial _buildSpeedDial(BuildContext context, Concert concert) {
    return SpeedDial(
      icon: Icons.edit,
      backgroundColor: AppColors.accentPurple,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.image),
          label: 'Change Picture',
          onTap: () => _dialogHelpers.showImageEditDialog(
            context,
            concertId,
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.title),
          label: 'Edit Details',
          onTap: () => _dialogHelpers.showDetailsEditDialog(
            context,
            concertId,
            concert,
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.queue_music),
          label: 'Edit Set List',
          onTap: () => _dialogHelpers.showSetlistEditDialog(
            context,
            concertId,
            concert,
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.calendar_today),
          label: 'Edit Dates',
          onTap: () => _dialogHelpers.showDatesEditDialog(
            context,
            concertId,
            concert,
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.location_on),
          label: 'Edit Location',
          onTap: () => _dialogHelpers.showLocationEditDialog(
            context,
            concertId,
            concert,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Concert>(
      stream: _firebaseService.getConcertDetails(concertId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No concert details available.',
                style: TextStyle(color: AppColors.textWhite70),
              ),
            ),
          );
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Concert Details',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConcertDetailsCard(
                      concert: snapshot.data!,
                      isAdmin: isAdmin,
                      concertId: concertId,
                    ),
                  ],
                ),
              ],
            ),
          ),
          floatingActionButton:
              isAdmin ? _buildSpeedDial(context, snapshot.data!) : null,
        );
      },
    );
  }
}
