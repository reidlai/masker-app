import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_input_field.dart';

class HealthDemographicsOrganism extends StatelessWidget {
  final TextEditingController? nameController;
  final TextEditingController? emailController;
  final TextEditingController? phoneController;
  final TextEditingController ageController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final double computedBmi;
  final ValueChanged<String>? onChanged;

  const HealthDemographicsOrganism({
    super.key,
    this.nameController,
    this.emailController,
    this.phoneController,
    required this.ageController,
    required this.weightController,
    required this.heightController,
    required this.computedBmi,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nameController != null || emailController != null || phoneController != null) ...[
          const Text(
            "Patient Identification (HIPAA Level 1 PHI)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (nameController != null)
            AppInputField(
              label: "Patient Full Name",
              hint: "David Miller",
              controller: nameController!,
              onChanged: onChanged,
            ),
          if (emailController != null) ...[
            const SizedBox(height: 12),
            AppInputField(
              label: "Patient Email Address",
              hint: "david.miller@example.com",
              controller: emailController!,
              onChanged: onChanged,
            ),
          ],
          if (phoneController != null) ...[
            const SizedBox(height: 12),
            AppInputField(
              label: "Patient Phone Number",
              hint: "(555) 019-8234",
              controller: phoneController!,
              onChanged: onChanged,
            ),
          ],
          const SizedBox(height: 20),
        ],
        const Text(
          "Health Baseline Demographics",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppInputField(
                label: "Age (years)",
                hint: "48",
                controller: ageController,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppInputField(
                label: "Weight (kg)",
                hint: "85",
                controller: weightController,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppInputField(
                label: "Height (cm)",
                hint: "178",
                controller: heightController,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Computed BMI",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      computedBmi.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
