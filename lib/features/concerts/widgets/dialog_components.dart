// lib/features/concerts/widgets/dialog_components.dart

import 'package:flutter/material.dart';
import 'package:capstone/core/constants/colors.dart';

class DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int? maxLines;

  const DialogTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textWhite),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textWhite70),
        hintStyle: const TextStyle(color: AppColors.textWhite60),
      ),
    );
  }
}

class DialogActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading;
  final String confirmText;

  const DialogActionButtons({
    super.key,
    required this.onCancel,
    this.onConfirm,
    this.isLoading = false,
    this.confirmText = 'Update',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textWhite70),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: isLoading ? null : onConfirm,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                  ),
                )
              : Text(
                  confirmText,
                  style: const TextStyle(color: AppColors.textWhite),
                ),
        ),
      ],
    );
  }
}

class DialogError extends StatelessWidget {
  final String message;

  const DialogError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }
}