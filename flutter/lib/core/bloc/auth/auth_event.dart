abstract class AuthEvent {
  const AuthEvent();
}

class AuthPasskeySubmitted extends AuthEvent {
  const AuthPasskeySubmitted();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
