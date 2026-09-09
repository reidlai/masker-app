import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/app_flow/app_flow_bloc.dart';
import '../../core/bloc/app_flow/app_flow_event.dart';
import '../../core/bloc/app_flow/app_flow_state.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';

/// First-run onboarding wizard shell (Story 1.9). The step bodies are
/// placeholders — Stories 1.10 (Register), 1.11 (Medical Profile) and 1.12
/// (Passkey Enrollment) replace each with its real screen and repo call.
class OnboardingWizardPage extends StatelessWidget {
  const OnboardingWizardPage({super.key});

  static const _order = [
    OnboardingStep.register,
    OnboardingStep.medicalProfile,
    OnboardingStep.passkeyEnrollment,
  ];

  static const _labels = {
    OnboardingStep.register: 'Register',
    OnboardingStep.medicalProfile: 'Medical Profile',
    OnboardingStep.passkeyEnrollment: 'Passkey Enrollment',
  };

  // Real screens land in Stories 1.10 (Register), 1.11 (Medical Profile) and
  // 1.12 (Passkey Enrollment).

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
                    child: Center(
                      child: Column(
                        key: Key('onboarding-step-${step.name}'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _labels[step]!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This step is coming soon.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index > 0)
                    AppButton(
                      label: 'Back',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context
                          .read<AppFlowBloc>()
                          .add(const AppFlowOnboardingStepBack()),
                    ),
                  if (index > 0) const SizedBox(height: 12),
                  AppButton(
                    label: index == _order.length - 1 ? 'Finish' : 'Continue',
                    variant: AppButtonVariant.primary,
                    onPressed: () => context
                        .read<AppFlowBloc>()
                        .add(const AppFlowOnboardingStepAdvanced()),
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
