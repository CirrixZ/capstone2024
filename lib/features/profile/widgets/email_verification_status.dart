import 'package:capstone/core/constants/colors.dart';
import 'package:flutter/material.dart';

class EmailVerificationStatus extends StatelessWidget {
  final bool isVerified;
  final VoidCallback? onSendVerification;
  final String? cooldownMessage;

  const EmailVerificationStatus({
    super.key,
    required this.isVerified,
    this.onSendVerification,
    this.cooldownMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.warning,
              color: isVerified ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(
              isVerified ? 'Email Verified' : 'Email Not Verified',
              style: TextStyle(
                color: isVerified ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
        if (!isVerified) ...[
          const SizedBox(height: 8),
          if (cooldownMessage != null)
            Text(
              cooldownMessage!,
              style: TextStyle(
                color: AppColors.textWhite70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            )
          else
            TextButton(
              onPressed: onSendVerification,
              child: const Text(
                'Send Verification Email',
                style: TextStyle(color: AppColors.borderColor),
              ),
            ),
        ],
      ],
    );
  }
}