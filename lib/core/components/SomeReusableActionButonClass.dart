import 'package:flutter/material.dart';

// ActionButton Class for Reusability of Buttons
class ActionButton extends StatelessWidget {
  final String label;

  const ActionButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.purpleAccent, // Button text color
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        // Define button functionality here
      },
      child: Text(label),
    );
  }
}