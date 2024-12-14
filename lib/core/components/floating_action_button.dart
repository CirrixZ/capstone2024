import 'package:capstone/core/constants/colors.dart';
import 'package:flutter/material.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final String labelText;
  final IconData iconData;
  final VoidCallback onPressed;

  const CustomFloatingActionButton({
    super.key,
    required this.labelText,
    required this.iconData,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor:
          AppColors.accentPurple, // Make FAB background transparent
      label: Text(
        labelText,
        style: const TextStyle(fontSize: 16),
      ),
      icon: Icon(
        iconData,
        size: 24,
      ),
    );
  }
}
