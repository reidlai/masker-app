import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';

class ApneaAlertOverlay extends StatelessWidget {
  final int countdownSeconds;
  final VoidCallback onPatientSafe;

  const ApneaAlertOverlay({
    super.key,
    required this.countdownSeconds,
    required this.onPatientSafe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF991B1B), // Dark Red
            Color(0xFF450A0A), // Deep Red
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Siren Icon Box
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 24),
              const Text(
                "Breathing Pause Detected!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Nocturnal Obstructive Apnea Breach Detected (>10s Airflow Drop).",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 36),

              // Countdown Ring
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${countdownSeconds}s",
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      "To Cloud Dispatch",
                      style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // 64dp Prominent Touch Target Dismiss Button
              AppButton(
                label: "I'M SAFE / I'M AWAKE",
                variant: AppButtonVariant.emergency,
                onPressed: onPatientSafe,
              ),
              const SizedBox(height: 20),
              const Text(
                "⚠️ Tier-2 Caregiver SMS/Voice Call will be dispatched if unacknowledged after 30s.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
