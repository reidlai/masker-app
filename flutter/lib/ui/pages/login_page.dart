import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isAuthenticating = false;

  void _authenticatePasskey() async {
    setState(() => _isAuthenticating = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isAuthenticating = false);
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Brand Logo & Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentGreen, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.air, color: AppColors.accentGreen, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                "Sleep Apnea App",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "D-BAND Integrated Respiratory Platform",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Passkey Card
              Container(
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
                        color: AppColors.accentGreen.withOpacity(0.1),
                        border: Border.all(color: AppColors.accentGreen, width: 2),
                      ),
                      child: const Icon(Icons.fingerprint, color: AppColors.accentGreen, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Biometric Passkey Required",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                      isLoading: _isAuthenticating,
                      variant: AppButtonVariant.primary,
                      icon: const Icon(Icons.verified_user_outlined, color: Colors.white),
                      onPressed: _authenticatePasskey,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                "🔒 HIPAA §164.312 Protected · FIDO2 Hardware Encryption",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
