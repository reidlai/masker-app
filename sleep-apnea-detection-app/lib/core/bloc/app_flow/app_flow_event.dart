import 'package:equatable/equatable.dart';

/// Events for [AppFlowBloc] — the boot resolve, the onboarding-wizard steps,
/// login success, logout / unregister, and the permission-primer transitions.
abstract class AppFlowEvent extends Equatable {
  const AppFlowEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispatched by `AppFlowBloc` on construction (and after an unregister): read
/// the persisted `OnboardingGate` flag and route `resolving` → `loggedOut`
/// (returning user) or `onboarding` (fresh install).
class AppFlowResolveRequested extends AppFlowEvent {
  const AppFlowResolveRequested();
}

/// The user unregistered their account. Distinct from [AppFlowLogoutRequested]:
/// the onboarding flag has been cleared, so the flow re-resolves to
/// `onboarding`, not `loggedOut`.
class AppFlowUnregistered extends AppFlowEvent {
  const AppFlowUnregistered();
}

/// The user completed passkey login. [needsOnboarding] is set by `main` after
/// `ProfileSession.hydrate()` when no `UserProfile` is present — a new or
/// just-unregistered user is routed to the onboarding wizard instead of the
/// permission-check path.
class AppFlowLoginSucceeded extends AppFlowEvent {
  final bool needsOnboarding;

  const AppFlowLoginSucceeded({this.needsOnboarding = false});

  @override
  List<Object?> get props => [needsOnboarding];
}

/// Advance the onboarding wizard to the next step (past the last → ready).
class AppFlowOnboardingStepAdvanced extends AppFlowEvent {
  const AppFlowOnboardingStepAdvanced();
}

/// Move the onboarding wizard back one step (no-op on the first step).
class AppFlowOnboardingStepBack extends AppFlowEvent {
  const AppFlowOnboardingStepBack();
}

/// "Retry" on the permission-check-failed screen.
class AppFlowPermissionRetryRequested extends AppFlowEvent {
  const AppFlowPermissionRetryRequested();
}

/// The one-time Bluetooth permission primer was completed.
class AppFlowPrimerCompleted extends AppFlowEvent {
  const AppFlowPrimerCompleted();
}

/// The user logged out — return the flow to [AppFlowStage.loggedOut] so the
/// root renders the login screen again.
class AppFlowLogoutRequested extends AppFlowEvent {
  const AppFlowLogoutRequested();
}
