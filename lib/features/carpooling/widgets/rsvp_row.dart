import 'package:flutter/material.dart';
import 'package:capstone/features/carpooling/widgets/rsvp_button.dart';

class RsvpRow extends StatelessWidget {
  final String userRsvp;
  final bool isLoading;
  final Function(String) onRsvp;

  const RsvpRow({
    super.key,
    required this.userRsvp,
    required this.isLoading,
    required this.onRsvp,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          RsvpButton(
            label: 'Going',
            icon: Icons.check_circle,
            color: Colors.green,
            isSelected: userRsvp == 'going',
            onPressed: isLoading ? null : () => onRsvp('going'),
          ),
          const SizedBox(width: 8), // Add spacing between buttons
          RsvpButton(
            label: 'Maybe',
            icon: Icons.help_outline,
            color: Colors.orange,
            isSelected: userRsvp == 'maybe',
            onPressed: isLoading ? null : () => onRsvp('maybe'),
          ),
          const SizedBox(width: 8), // Add spacing between buttons
          RsvpButton(
            label: 'Not Going',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            isSelected: userRsvp == 'not_going',
            onPressed: isLoading ? null : () => onRsvp('not_going'),
          ),
        ],
      ),
    );
  }
}