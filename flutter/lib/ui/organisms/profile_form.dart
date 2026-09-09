import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/profile/profile_bloc.dart';
import '../../core/bloc/profile/profile_event.dart';
import '../../core/bloc/profile/profile_state.dart';
import '../../core/data/profile_repository.dart';
import '../../core/profile/user_profile.dart';
import '../../core/profile/user_profile_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validation/profile_validators.dart' as validators;
import '../atoms/app_button.dart';
import 'emergency_contact_organism.dart';
import 'health_demographics_organism.dart';
import 'user_header_organism.dart';

/// The medical-profile form body — patient identity, health baseline, caregiver
/// contact — shared by [ProfilePage] (Settings edit mode) and the onboarding
/// wizard's Medical Profile step (Story 1.11). It owns the eight text
/// controllers, the [ProfileBloc], client-side validation, and the optimistic
/// save; the hosts differ only in chrome and in what happens after a save:
///
/// - Settings wraps this in a `Scaffold` + AppBar tick and, on success, shows a
///   "Medical profile saved ✓" snackbar ([onSaved] left null).
/// - The wizard passes [onSaved] to advance the flow; the success snackbar is
///   suppressed because the step is being torn down as the wizard advances.
///
/// Drive a save from outside the body (the Settings AppBar tick) with a
/// `GlobalKey<ProfileFormState>`: `key.currentState?.save()`.
class ProfileForm extends StatefulWidget {
  /// Called once after a successful persist. When null, a success snackbar is
  /// shown instead.
  final VoidCallback? onSaved;

  /// Scroll-view padding. Defaults to the Settings look; the wizard step passes
  /// vertical-only since it already sits inside the wizard's own inset.
  final EdgeInsetsGeometry padding;

  const ProfileForm({
    super.key,
    this.onSaved,
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  State<ProfileForm> createState() => ProfileFormState();
}

class ProfileFormState extends State<ProfileForm> {
  final ProfileBloc _bloc =
      ProfileBloc(initial: UserProfileService.instance.current);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _caregiverNameController;
  late final TextEditingController _emergencyPhoneController;

  bool _saving = false;
  Map<String, String?> _errors = const {};

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
    // The organism shares one callback across its fields; mirror the two that
    // drive the BMI so the bloc re-derives it.
    _bloc.add(ProfileFieldChanged(ProfileField.weight, _weightController.text));
    _bloc.add(ProfileFieldChanged(ProfileField.height, _heightController.text));
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Map<String, String?> _validate() {
    return {
      'name': validators.requiredError(_nameController.text, field: 'Full name'),
      'email': validators.emailError(_emailController.text),
      'phone': validators.phoneError(_phoneController.text),
      'age': validators.ageError(_ageController.text),
      'weight':
          validators.positiveNumberError(_weightController.text, field: 'Weight'),
      'height':
          validators.positiveNumberError(_heightController.text, field: 'Height'),
      'caregiverName': validators.requiredError(_caregiverNameController.text,
          field: 'Caregiver name'),
      'caregiverPhone': validators.phoneError(_emergencyPhoneController.text),
    };
  }

  /// Validate, then persist. Shared by the primary CTA and (via a GlobalKey) the
  /// Settings AppBar tick. Invalid input surfaces inline errors and does not
  /// persist. Re-entrant calls while a save is in flight are ignored.
  Future<void> save() async {
    if (_saving) return;
    final errors = _validate();
    if (errors.values.any((e) => e != null)) {
      setState(() => _errors = errors);
      return;
    }
    setState(() {
      _errors = const {};
      _saving = true;
    });
    try {
      await _persist();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persist() async {
    final current = UserProfileService.instance.current;
    final updated = UserProfile(
      userId: current?.userId ?? 'demo-user',
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      gender: current?.gender ?? '',
      weightKg: double.tryParse(_weightController.text.trim()) ?? 0,
      heightCm: double.tryParse(_heightController.text.trim()) ?? 0,
      computedBmi: _bloc.state.computedBmi,
      caregiverName: _caregiverNameController.text.trim(),
      caregiverPhone: _emergencyPhoneController.text.trim(),
    );

    // Optimistic: update the in-memory store first, then the (simulated) server
    // write. A write failure leaves the optimistic value and surfaces an error.
    UserProfileService.instance.set(updated);
    _bloc.add(ProfileFieldChanged(ProfileField.name, updated.fullName));

    try {
      await ProfileRepository.instance.saveUserProfile(updated);
    } catch (_) {
      if (mounted) _snack("Couldn't save — try again.", Colors.redAccent);
      return;
    }
    if (!mounted) return;
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      _snack("Medical profile saved ✓", AppColors.accentGreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: _bloc,
      builder: (context, state) {
        return SingleChildScrollView(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              HealthDemographicsOrganism(
                nameController: _nameController,
                emailController: _emailController,
                phoneController: _phoneController,
                ageController: _ageController,
                weightController: _weightController,
                heightController: _heightController,
                computedBmi: state.computedBmi,
                onChanged: _onDemographicsChanged,
                nameError: _errors['name'],
                emailError: _errors['email'],
                phoneError: _errors['phone'],
                ageError: _errors['age'],
                weightError: _errors['weight'],
                heightError: _errors['height'],
              ),
              const SizedBox(height: 24),
              EmergencyContactOrganism(
                nameController: _caregiverNameController,
                phoneController: _emergencyPhoneController,
                nameError: _errors['caregiverName'],
                phoneError: _errors['caregiverPhone'],
              ),
              const SizedBox(height: 32),
              AppButton(
                label: "Save & Continue",
                variant: AppButtonVariant.primary,
                isLoading: _saving,
                onPressed: save,
              ),
            ],
          ),
        );
      },
    );
  }
}
