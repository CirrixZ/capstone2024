import 'package:capstone/core/components/custom_dialog.dart';
import 'package:capstone/core/components/floating_action_button.dart';
import 'package:capstone/features/chat/screens/carpool_chat_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/carpooling/models/carpool_model.dart';
import 'package:capstone/features/carpooling/widgets/carpool_card.dart';
import 'package:capstone/core/services/firebase_service.dart';

class CarpoolList extends StatelessWidget {
  final String concertId;
  final bool isVerified;
  final FirebaseService _firebaseService = FirebaseService();

  CarpoolList({
    super.key,
    required this.concertId,
    this.isVerified = false, // Default to false
  });

  // Method to create carpool
  void _showAddCarpoolDialog(BuildContext context) {
    final feeController = TextEditingController();
    final slotsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Add Carpool',
        requiresImage: true,
        imageHint: 'Add Carpool Banner',
        fields: [
          CustomDialogField(
            label: 'Fee',
            hint: 'Enter fee amount',
            controller: feeController,
            keyboardType: TextInputType.number,
            validator: (value) {
              final fee = int.tryParse(value ?? '');
              if (fee == null) {
                return 'Please enter a valid number';
              }
              if (fee > 3000) {
                return 'Fee cannot exceed 3000';
              }
              return null;
            },
          ),
          CustomDialogField(
            label: 'Available Slots',
            hint: 'Enter number of slots',
            controller: slotsController,
            keyboardType: TextInputType.number,
            validator: (value) {
              final slots = int.tryParse(value ?? '');
              if (slots == null || slots <= 0) {
                return 'Please enter a valid number of slots';
              }
              if (slots > 20) {
                return 'Slots cannot exceed 20';
              }
              return null;
            },
          ),
        ],
        onSubmit: (values, image) async {
          if (image == null) return;

          final String fileName =
              'carpool_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance.ref().child(fileName);
          await ref.putFile(image);
          final String imageUrl = await ref.getDownloadURL();

          await _firebaseService.createCarpool(
            concertId: concertId,
            fee: int.parse(values['Fee']!),
            slots: int.parse(values['Available Slots']!),
            imageUrl: imageUrl,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Carpool List',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Carpool>>(
                  stream: _firebaseService.getCarpools(concertId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No carpools available.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      padding: const EdgeInsets.only(
                          bottom: 60), // Add padding for FAB
                      itemBuilder: (context, index) {
                        Carpool carpool = snapshot.data![index];
                        return CarpoolCard(
                          carpool: carpool,
                          concertId: concertId,
                          onJoin: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CarpoolChatScreen(
                                  carpoolId: carpool.chatRoomId,
                                  concertId: concertId,
                                  driverId: carpool.driverId,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: CustomFloatingActionButton(
          labelText: 'Make Carpool',
          iconData: Icons.add,
          onPressed: () => _showAddCarpoolDialog(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
  }
}
