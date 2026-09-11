import 'package:equatable/equatable.dart';

/// The app-flow gate. On boot [resolving] reads the `OnboardingGate` flag and
/// routes to [loggedOut] (returning user → sign-in) or [onboarding] (fresh
/// install → wizard, no sign-in screen). Post-`loggedOut`, a login success does
/// not jump straight to the tab shell — a returning user has its live Bluetooth
/// permission checked and, if not yet granted, routes through the one-time
/// priming screen. Permission gating is always a live status check.
enum AppFlowStage {
  /// Boot-time: reading the persisted onboarding flag. Renders a spinner.
  resolving,
  loggedOut,
  onboarding,
  checkingPermission,
  permissionCheckFailed,
  needsPrimer,
  ready,
}

/// Steps of the first-run onboarding wizard. `done` is the terminal marker —
/// advancing past `passkeyEnrollment` moves the flow to [AppFlowStage.ready].
enum OnboardingStep { register, medicalProfile, passkeyEnrollment, done }

class AppFlowState extends Equatable {
  final AppFlowStage stage;
  final OnboardingStep onboardingStep;

  const AppFlowState({
    this.stage = AppFlowStage.resolving,
    this.onboardingStep = OnboardingStep.register,
  });

  AppFlowState copyWith({
    AppFlowStage? stage,
    OnboardingStep? onboardingStep,
  }) =>
      AppFlowState(
        stage: stage ?? this.stage,
        onboardingStep: onboardingStep ?? this.onboardingStep,
      );

  @override
  List<Object?> get props => [stage, onboardingStep];
}
