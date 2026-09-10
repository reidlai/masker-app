import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthInProgress extends AuthState {
  const AuthInProgress();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

class AuthFailure extends AuthState {
  final String errorMessage;
  const AuthFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Shown when passkey sign-in / enrollment cannot proceed: the simulator is off
/// and no real FIDO2/WebAuthn authenticator is wired yet. One source of truth for
/// `AuthBloc` and the onboarding passkey step so the two never drift. Kept
/// build-agnostic — a release build has no toggle to point at.
const String passkeyUnavailableMessage =
    "Passkey sign-in isn't available yet — real FIDO2 authentication is not "
    "wired up in this build.";

/// Passkey sign-in cannot proceed because the simulator is off and no real
/// FIDO2/WebAuthn authenticator is wired yet. Distinct from [AuthFailure]: this
/// is an expected "not available yet" condition, not a fault.
class AuthUnavailable extends AuthState {
  final String message;
  const AuthUnavailable([this.message = passkeyUnavailableMessage]);

  @override
  List<Object?> get props => [message];
}
