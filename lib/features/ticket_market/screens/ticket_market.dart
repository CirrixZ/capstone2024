import 'package:capstone/core/components/custom_dialog.dart';
import 'package:capstone/core/components/floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/ticket_market/models/ticket_model.dart';
import 'package:capstone/features/ticket_market/widgets/ticket_card.dart';
import 'package:capstone/core/services/firebase_service.dart';

class TicketMarketPage extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();
  final String concertId;

  TicketMarketPage({Key? key, required this.concertId}) : super(key: key);

  void _showAddTicketDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Add Ticket Link',
        fields: [
          CustomDialogField(
            label: 'Ticket Name',
            hint: 'Enter ticket name',
            controller: nameController,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a ticket name';
              }
              return null;
            },
          ),
          CustomDialogField(
            label: 'Ticket URL',
            hint: 'Enter ticket URL',
            controller: urlController,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a URL';
              }
              return null;
            },
          ),
        ],
        onSubmit: (values, _) async {
          await _firebaseService.createTicket(
            concertId: concertId,
            ticketName: values['Ticket Name']!,
            url: values['Ticket URL']!,
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
              'Ticket Market',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Availability of tickets may vary',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Ticket>>(
                stream: _firebaseService.getTickets(concertId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No tickets available.'));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return TicketCard(
                        ticket: snapshot.data![index],
                        concertId: concertId,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: _firebaseService.userAdminStream(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return CustomFloatingActionButton(
              labelText: 'Add Ticket Link',
              iconData: Icons.add,
              onPressed: () => _showAddTicketDialog(context),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }
}
