import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/auth/auth_bloc.dart';
import 'package:masker_app/core/bloc/auth/auth_event.dart';
import 'package:masker_app/core/bloc/auth/auth_state.dart';

void main() {
  group('AuthBloc Unit Tests', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc(
        passkeyAuthenticator: () async {
          await Future.delayed(const Duration(milliseconds: 10));
        },
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    test('emits [AuthInProgress, AuthAuthenticated] when AuthPasskeySubmitted is added', () async {
      final expectedStates = [
        isA<AuthInProgress>(),
        isA<AuthAuthenticated>(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));

      authBloc.add(const AuthPasskeySubmitted());
    });

    test('emits [AuthInitial] when AuthLogoutRequested is added', () async {
      authBloc.add(const AuthLogoutRequested());
      await expectLater(authBloc.stream, emits(isA<AuthInitial>()));
    });
  });
}
