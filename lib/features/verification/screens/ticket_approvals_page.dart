import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/verification/models/ticket_verification_model.dart';

class TicketApprovalsPage extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();

  TicketApprovalsPage({super.key});

  Future<void> _showImageDialog(BuildContext context, String imageUrl) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2F1552),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(imageUrl),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Close', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, String verificationId) {
    final reasonController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2F1552),
        title: const Text('Reject Verification',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF7000FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              await _firebaseService.rejectVerification(
                  verificationId, reasonController.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Approvals',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF180B2D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<TicketVerification>>(
        stream: _firebaseService.getPendingVerifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7000FF)),
            ));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70)),
            );
          }

          final verifications = snapshot.data ?? [];

          if (verifications.isEmpty) {
            return const Center(
              child: Text('No pending verifications',
                  style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final verification = snapshot.data![index];
              return Card(
                color: const Color(0xFF2F1552),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(verification.userName,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Submitted: ${verification.submittedAt.toString().split('.')[0]}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _firebaseService
                            .approveVerification(verification.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () =>
                            _showRejectDialog(context, verification.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.blue),
                        onPressed: () =>
                            _showImageDialog(context, verification.imageUrl),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
