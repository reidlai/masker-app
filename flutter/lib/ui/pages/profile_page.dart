import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';
import '../atoms/app_input_field.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _ageController = TextEditingController(text: "48");
  final TextEditingController _weightController = TextEditingController(text: "85");
  final TextEditingController _heightController = TextEditingController(text: "178");
  final TextEditingController _emergencyPhoneController = TextEditingController(text: "+1 555-019-2834");

  double _computedBmi = 26.8;

  void _calculateBmi() {
    final double? weight = double.tryParse(_weightController.text);
    final double? heightCm = double.tryParse(_heightController.text);
    if (weight != null && heightCm != null && heightCm > 0) {
      final double heightM = heightCm / 100.0;
      setState(() {
        _computedBmi = weight / (heightM * heightM);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Medical Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.accentGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Health profile saved ✓"),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.accentGreen,
                      child: Text("D", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("David (Persona A)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text("High-Risk Nocturnal Apnea Patient", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("Health Baseline Demographics", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AppInputField(
                      label: "Age (years)",
                      hint: "48",
                      controller: _ageController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInputField(
                      label: "Weight (kg)",
                      hint: "85",
                      controller: _weightController,
                      onChanged: (_) => _calculateBmi(),
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
                      controller: _heightController,
                      onChanged: (_) => _calculateBmi(),
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
                          const Text("Computed BMI", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Text(
                            _computedBmi.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text("Tier-2 Caregiver Emergency Contact", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              AppInputField(
                label: "Caregiver Phone Number",
                hint: "+1 555-019-2834",
                controller: _emergencyPhoneController,
              ),
              const SizedBox(height: 32),

              AppButton(
                label: "Save & Continue",
                variant: AppButtonVariant.primary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Medical profile updated ✓"), backgroundColor: AppColors.accentGreen),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
