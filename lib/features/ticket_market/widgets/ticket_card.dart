import 'package:capstone/core/constants/colors.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/ticket_market/models/ticket_model.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final String concertId;
  final FirebaseService _firebaseService = FirebaseService();

  TicketCard({
    Key? key,
    required this.ticket,
    required this.concertId,
  }) : super(key: key);

  Future<void> _showDeleteDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2F1552),
          title: Text('Delete Ticket', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete this ticket?',
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
                  await _firebaseService.deleteTicket(concertId, ticket.id);
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xff2F1552),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.link, color: AppColors.iconColor),
                  title: Text(
                    ticket.ticketName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    ticket.url,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFF9C47FF)),
                      ),
                    ),
                    onPressed: () async {
                      final urlToLaunch = ticket.url.startsWith('http')
                          ? ticket.url
                          : 'https://${ticket.url}';

                      try {
                        final Uri url = Uri.parse(urlToLaunch);
                        if (!await launchUrlString(
                          url.toString(),
                          mode: LaunchMode.externalApplication,
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Could not open ${ticket.url}')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid URL: ${ticket.url}')),
                        );
                      }
                    },
                    child: Text('View',
                        style: const TextStyle(color: Colors.white)),
                  ),
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
          ),
        );
      },
    );
  }
}
