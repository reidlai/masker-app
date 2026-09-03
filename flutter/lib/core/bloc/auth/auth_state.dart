abstract class AuthState {
  const AuthState();
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
}
