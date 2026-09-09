import 'package:equatable/equatable.dart';

/// Events for [AppFlowBloc] — the three transitions the root widget used to
/// drive with `setState`.
abstract class AppFlowEvent extends Equatable {
  const AppFlowEvent();

  @override
  List<Object?> get props => const [];
}

/// The user completed passkey login.
class AppFlowLoginSucceeded extends AppFlowEvent {
  const AppFlowLoginSucceeded();
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
