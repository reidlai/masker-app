import 'package:equatable/equatable.dart';

/// The post-login flow gate. A login success does not jump straight to the tab
/// shell — a new / just-unregistered user is routed through the onboarding
/// wizard; a returning user has its live Bluetooth permission checked and, if
/// not yet granted, routes through the one-time priming screen. Gating is
/// always a live status check, never a persisted "seen it" flag.
enum AppFlowStage {
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
    this.stage = AppFlowStage.loggedOut,
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
