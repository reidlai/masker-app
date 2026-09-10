import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Future<void> Function()? _passkeyAuthenticator;

  /// Returns whether the developer "Passkey Simulator" flag is currently on.
  /// Defaults to always-off so existing callers/tests keep their behavior;
  /// `main` injects the real `DEV_MODE`-gated [PasskeySimulatorConfig] read.
  final bool Function() _isPasskeySimulatorEnabled;

  AuthBloc({
    Future<void> Function()? passkeyAuthenticator,
    bool Function()? isPasskeySimulatorEnabled,
  })  : _passkeyAuthenticator = passkeyAuthenticator,
        _isPasskeySimulatorEnabled = isPasskeySimulatorEnabled ?? (() => false),
        super(const AuthInitial()) {
    on<AuthPasskeySubmitted>(
      _onPasskeySubmitted,
      transformer: (events, mapper) => events
          .throttleTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );

    on<AuthLogoutRequested>((event, emit) {
      emit(const AuthInitial());
    });

    on<AuthUnregisterRequested>((event, emit) {
      emit(const AuthInitial());
    });
  }

  Future<void> _onPasskeySubmitted(
    AuthPasskeySubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInProgress());
    try {
      if (_isPasskeySimulatorEnabled()) {
        // Simulated passkey path — brief delay, always authenticates.
        await Future.delayed(const Duration(milliseconds: 800));
        emit(const AuthAuthenticated());
      } else if (_passkeyAuthenticator != null) {
        // TODO(FIDO): real FIDO2/WebAuthn authenticator.
        await _passkeyAuthenticator!();
        emit(const AuthAuthenticated());
      } else {
        // Simulator off and no real authenticator wired: there is no way to
        // authenticate. Surface an explicit unavailable state — never a fake
        // session. A real FIDO2 ceremony replaces this branch. TODO(FIDO).
        emit(const AuthUnavailable());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
