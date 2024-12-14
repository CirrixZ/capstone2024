import 'package:flutter/material.dart';
import 'package:capstone/core/components/custom_dialog.dart';
import 'dart:io';

class TicketVerificationDialog extends StatelessWidget {
  final Function(File) onSubmit;

  const TicketVerificationDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Ticket Verification Required',
      fields: const [],
      requiresImage: true,
      imageHint: 'Upload your ticket image',
      submitButtonText: 'Submit',
      onSubmit: (values, image) async {
        if (image == null) {
          throw Exception('Please select a ticket image');
        }
        onSubmit(image);
      },
    );
  }
}