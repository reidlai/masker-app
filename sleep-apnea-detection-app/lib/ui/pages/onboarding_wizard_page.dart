import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/app_flow/app_flow_bloc.dart';
import '../../core/bloc/app_flow/app_flow_event.dart';
import '../../core/bloc/app_flow/app_flow_state.dart';
import '../../core/bloc/auth/auth_state.dart' show passkeyUnavailableMessage;
import '../../core/config/passkey_simulator_config.dart';
import '../../core/data/profile_repository.dart';
import '../../core/profile/user_profile_service.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';
import '../organisms/profile_form.dart';

/// First-run onboarding wizard shell (Story 1.9). All three steps are real:
/// Register (1.10), Medical Profile (1.11), Passkey Enrollment (1.12). Every
/// step carries its own primary action — the wizard is forward-only, with no
/// generic Continue / Back / Finish.
class OnboardingWizardPage extends StatelessWidget {
  const OnboardingWizardPage({super.key});

  static const _order = [
    OnboardingStep.register,
    OnboardingStep.medicalProfile,
    OnboardingStep.passkeyEnrollment,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppFlowBloc, AppFlowState>(
      builder: (context, flow) {
        final step = _order.contains(flow.onboardingStep)
            ? flow.onboardingStep
            : OnboardingStep.register;
        final index = _order.indexOf(step);

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
                        OnboardingStep.passkeyEnrollment =>
                          const _PasskeyEnrollmentStep(),
                        // Unreachable: `step` is always one of `_order`.
                        _ => const SizedBox.shrink(),
                      },
                    ),
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

/// Onboarding step 3 (Story 1.12): FIDO2 passkey enrollment. Mirrors
/// [_RegisterStep]: owns its repo call, advances the wizard only on success.
class _PasskeyEnrollmentStep extends StatefulWidget {
  const _PasskeyEnrollmentStep();

  @override
  State<_PasskeyEnrollmentStep> createState() => _PasskeyEnrollmentStepState();
}

class _PasskeyEnrollmentStepState extends State<_PasskeyEnrollmentStep> {
  bool _busy = false;
  String? _error;

  bool get _simulated => passkeySimulatorActive(
        developerBuild: kDebugMode ||
            const bool.fromEnvironment('DEV_MODE', defaultValue: false),
      );

  Future<void> _createPasskey() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_simulated) {
        // Real FIDO2/WebAuthn enrollment is not wired yet (TODO(FIDO)). With
        // the simulator off there is no way to create a passkey — surface an
        // explicit unavailable state instead of recording a fake credential.
        setState(() => _error = passkeyUnavailableMessage);
        return;
      }
      // Simulated enrollment: record a credential and advance the wizard.
      final user = await ProfileRepository.instance.enrollPasskey();
      if (!mounted) return;
      UserProfileService.instance.set(user);
      context.read<AppFlowBloc>().add(const AppFlowOnboardingStepAdvanced());
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Couldn't create your passkey — try again.");
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
          'Set up your passkey',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _simulated
              ? 'Simulated enrollment · developer. A passkey credential is '
                  'recorded on your account without a biometric prompt.'
              : "Real FIDO2 passkey enrollment isn't wired up in this build.",
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 13,
              // "Not wired up" is expected, not a fault — amber, not red.
              color: _error == passkeyUnavailableMessage
                  ? AppColors.warningAmber
                  : AppColors.dangerRed,
            ),
          ),
        ],
        const Spacer(),
        AppButton(
          key: const Key('onboarding-create-passkey'),
          label: 'Create Passkey',
          isLoading: _busy,
          variant: AppButtonVariant.primary,
          onPressed: _createPasskey,
        ),
      ],
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
