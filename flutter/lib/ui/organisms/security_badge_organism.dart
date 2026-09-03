import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SecurityBadgeOrganism extends StatelessWidget {
  final String text;

  const SecurityBadgeOrganism({
    super.key,
    this.text = "🔒 HIPAA §164.312 Protected · FIDO2 Hardware Encryption",
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
