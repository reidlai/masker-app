import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

class AuthPasskeySubmitted extends AuthEvent {
  const AuthPasskeySubmitted();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthUnregisterRequested extends AuthEvent {
  const AuthUnregisterRequested();
}
