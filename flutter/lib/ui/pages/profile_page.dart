import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/profile/profile_bloc.dart';
import '../../core/bloc/profile/profile_event.dart';
import '../../core/bloc/profile/profile_state.dart';
import '../../core/profile/user_profile_service.dart';
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
  final ProfileBloc _bloc = ProfileBloc(initial: UserProfileService.instance.current);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _caregiverNameController;
  late final TextEditingController _emergencyPhoneController;

  @override
  void initState() {
    super.initState();
    final s = _bloc.state;
    _nameController = TextEditingController(text: s.name);
    _emailController = TextEditingController(text: s.email);
    _phoneController = TextEditingController(text: s.phone);
    _ageController = TextEditingController(text: s.age);
    _weightController = TextEditingController(text: s.weight);
    _heightController = TextEditingController(text: s.height);
    _caregiverNameController = TextEditingController(text: s.caregiverName);
    _emergencyPhoneController = TextEditingController(text: s.emergencyPhone);
  }

  @override
  void dispose() {
    _bloc.close();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _caregiverNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _onDemographicsChanged(String _) {
    // The organism shares one callback across its fields; mirror the fields
    // that drive the BMI so the bloc re-derives it (identical to
    // `_calculateBmi()`).
    _bloc.add(ProfileFieldChanged(ProfileField.weight, _weightController.text));
    _bloc.add(ProfileFieldChanged(ProfileField.height, _heightController.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: _bloc,
      builder: (context, state) {
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
                  // Encapsulated User Card Header Organism — derived from the
                  // loaded profile, with a placeholder when the store is empty.
                  UserHeaderOrganism(
                    firstName: state.name.trim().isNotEmpty
                        ? state.name.trim().split(' ').first
                        : "New",
                    customTitle: state.name.trim().isNotEmpty
                        ? state.name
                        : "Complete your profile",
                    subtitle: state.name.trim().isNotEmpty
                        ? "High-Risk Nocturnal Apnea Patient"
                        : "No profile on file",
                    showNotificationBell: false,
                    showCardBackground: true,
                  ),
                  const SizedBox(height: 24),

                  // Health Demographics Organism with Patient Identification
                  HealthDemographicsOrganism(
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    ageController: _ageController,
                    weightController: _weightController,
                    heightController: _heightController,
                    computedBmi: state.computedBmi,
                    onChanged: _onDemographicsChanged,
                  ),
                  const SizedBox(height: 24),

                  // Emergency Contact Organism
                  EmergencyContactOrganism(
                    nameController: _caregiverNameController,
                    phoneController: _emergencyPhoneController,
                  ),
                  const SizedBox(height: 32),

                  AppButton(
                    label: "Save & Continue",
                    variant: AppButtonVariant.primary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Medical profile updated ✓"),
                            backgroundColor: AppColors.accentGreen),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
