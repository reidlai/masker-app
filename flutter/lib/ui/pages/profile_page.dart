import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';
import '../organisms/emergency_contact_organism.dart';
import '../organisms/health_demographics_organism.dart';
import '../organisms/user_header_organism.dart';

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
              // Encapsulated User Card Header Organism
              const UserHeaderOrganism(
                firstName: "David",
                customTitle: "David (Persona A)",
                subtitle: "High-Risk Nocturnal Apnea Patient",
                showNotificationBell: false,
                showCardBackground: true,
              ),
              const SizedBox(height: 24),

              // Health Demographics Organism
              HealthDemographicsOrganism(
                ageController: _ageController,
                weightController: _weightController,
                heightController: _heightController,
                computedBmi: _computedBmi,
                onChanged: (_) => _calculateBmi(),
              ),
              const SizedBox(height: 24),

              // Emergency Contact Organism
              EmergencyContactOrganism(
                phoneController: _emergencyPhoneController,
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
