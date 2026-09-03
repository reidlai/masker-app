import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Future<void> Function()? _passkeyAuthenticator;

  AuthBloc({Future<void> Function()? passkeyAuthenticator})
      : _passkeyAuthenticator = passkeyAuthenticator,
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
  }

  Future<void> _onPasskeySubmitted(
    AuthPasskeySubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInProgress());
    try {
      if (_passkeyAuthenticator != null) {
        await _passkeyAuthenticator!();
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
      }
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
