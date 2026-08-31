import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';
import '../atoms/app_input_field.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

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
              // App Logo & Title
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryTeal, width: 2),
                ),
                child: const Icon(Icons.masks, color: AppColors.primaryTeal, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                "Sleep Apnea Detection App",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const AppInputField(
                label: "Email Address",
                hint: "example@email.com",
              ),
              const SizedBox(height: 20),
              const AppInputField(
                label: "Password",
                hint: "********",
                isPassword: true,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: "Sign In",
                onPressed: onLoginSuccess,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: AppColors.primaryTeal),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () {},
                    child: const Text("Sign Up", style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
