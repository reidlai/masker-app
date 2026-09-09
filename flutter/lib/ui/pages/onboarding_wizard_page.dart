import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/app_flow/app_flow_bloc.dart';
import '../../core/bloc/app_flow/app_flow_event.dart';
import '../../core/bloc/app_flow/app_flow_state.dart';
import '../../core/data/profile_repository.dart';
import '../../core/profile/user_profile_service.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';
import '../organisms/profile_form.dart';

/// First-run onboarding wizard shell (Story 1.9). Step 1 (Register, Story 1.10)
/// and step 2 (Medical Profile, Story 1.11) are real; Passkey Enrollment (1.12)
/// is still a placeholder.
class OnboardingWizardPage extends StatelessWidget {
  const OnboardingWizardPage({super.key});

  static const _order = [
    OnboardingStep.register,
    OnboardingStep.medicalProfile,
    OnboardingStep.passkeyEnrollment,
  ];

  // Only steps that still render `_Placeholder` need a label here.
  static const _labels = {
    OnboardingStep.register: 'Register',
    OnboardingStep.passkeyEnrollment: 'Passkey Enrollment',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppFlowBloc, AppFlowState>(
      builder: (context, flow) {
        final step = _order.contains(flow.onboardingStep)
            ? flow.onboardingStep
            : OnboardingStep.register;
        final index = _order.indexOf(step);
        // Register and Medical Profile carry their own primary action; every
        // other step uses the generic Continue / Back.
        final selfActioned = step == OnboardingStep.register ||
            step == OnboardingStep.medicalProfile;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('Set up your account  ${index + 1}/${_order.length}'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProgressDots(count: _order.length, active: index),
                  const SizedBox(height: 32),
                  Expanded(
                    child: KeyedSubtree(
                      key: Key('onboarding-step-${step.name}'),
                      child: switch (step) {
                        OnboardingStep.register => const _RegisterStep(),
                        OnboardingStep.medicalProfile =>
                          const _MedicalProfileStep(),
                        _ => _Placeholder(label: _labels[step]!),
                      },
                    ),
                  ),
                  if (!selfActioned) ...[
                    if (index > 0) ...[
                      AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => context
                            .read<AppFlowBloc>()
                            .add(const AppFlowOnboardingStepBack()),
                      ),
                      const SizedBox(height: 12),
                    ],
                    AppButton(
                      label: index == _order.length - 1 ? 'Finish' : 'Continue',
                      variant: AppButtonVariant.primary,
                      onPressed: () => context
                          .read<AppFlowBloc>()
                          .add(const AppFlowOnboardingStepAdvanced()),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This step is coming soon.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Onboarding step 2 (Story 1.11): the medical-profile form in first-run mode.
/// Reuses [ProfileForm]; on a successful save it advances the wizard. No AppBar
/// tick and no generic Continue/Back — the form's own "Save & Continue" is the
/// only action.
class _MedicalProfileStep extends StatelessWidget {
  const _MedicalProfileStep();

  @override
  Widget build(BuildContext context) {
    return ProfileForm(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      onSaved: () => context
          .read<AppFlowBloc>()
          .add(const AppFlowOnboardingStepAdvanced()),
    );
  }
}

/// Onboarding step 1 (Story 1.10): HIPAA consent + account creation.
class _RegisterStep extends StatefulWidget {
  const _RegisterStep();

  @override
  State<_RegisterStep> createState() => _RegisterStepState();
}

class _RegisterStepState extends State<_RegisterStep> {
  bool _consented = false;
  bool _busy = false;
  String? _error;

  Future<void> _createAccount() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await ProfileRepository.instance.registerUser();
      if (!mounted) return;
      UserProfileService.instance.set(user);
      context.read<AppFlowBloc>().add(const AppFlowOnboardingStepAdvanced());
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Couldn't create your account — try again.");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Create your account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your health data is protected under HIPAA 45 CFR §164.312 — '
          'encrypted at rest and in transit, and gated behind your passkey.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          key: const Key('onboarding-consent-checkbox'),
          value: _consented,
          onChanged: _busy
              ? null
              : (v) => setState(() => _consented = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.accentGreen,
          title: const Text(
            'I agree to the HIPAA privacy & data terms',
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(fontSize: 13, color: AppColors.dangerRed),
          ),
        ],
        const Spacer(),
        AppButton(
          key: const Key('onboarding-create-account'),
          label: 'Create account',
          isLoading: _busy,
          variant: AppButtonVariant.primary,
          onPressed: _consented ? _createAccount : null,
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int count;
  final int active;

  const _ProgressDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i <= active ? AppColors.accentGreen : AppColors.cardBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
