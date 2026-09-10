import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';

class PasskeyAuthCardOrganism extends StatelessWidget {
  final bool isAuthenticating;
  final VoidCallback onAuthenticate;

  const PasskeyAuthCardOrganism({
    super.key,
    required this.isAuthenticating,
    required this.onAuthenticate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.accentGreen, width: 2),
            ),
            child: const Icon(Icons.fingerprint, color: AppColors.accentGreen, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            "Biometric Passkey Required",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Authenticate passwordlessly using native OS biometrics (Face ID / Touch ID / BiometricPrompt).",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: "Sign in with Passkey",
            isLoading: isAuthenticating,
            variant: AppButtonVariant.primary,
            icon: const Icon(Icons.verified_user_outlined, color: Colors.white),
            onPressed: onAuthenticate,
          ),
        ],
      ),
    );
  }
}
