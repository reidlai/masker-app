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

    test(
        'throttleTime(300ms) collapses a rapid burst of AuthPasskeySubmitted into one auth cycle',
        () async {
      final emitted = <AuthState>[];
      final sub = authBloc.stream.listen(emitted.add);

      authBloc.add(const AuthPasskeySubmitted());
      authBloc.add(const AuthPasskeySubmitted());
      authBloc.add(const AuthPasskeySubmitted());

      await Future.delayed(const Duration(milliseconds: 200));

      // Only the leading event ran; the two within the 300ms window were dropped.
      expect(
        emitted,
        equals([isA<AuthInProgress>(), isA<AuthAuthenticated>()]),
      );
      await sub.cancel();
    });
  });

  group('AuthBloc passkey simulator flag', () {
    test(
        'flag On authenticates via the simulated path even when the real authenticator throws',
        () async {
      final bloc = AuthBloc(
        isPasskeySimulatorEnabled: () => true,
        passkeyAuthenticator: () async => throw StateError('should not run'),
      );
      addTearDown(bloc.close);

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthInProgress>(), isA<AuthAuthenticated>()]),
      );

      bloc.add(const AuthPasskeySubmitted());
    });

    test(
        'flag Off routes to the real authenticator and surfaces its failure as AuthFailure',
        () async {
      final bloc = AuthBloc(
        isPasskeySimulatorEnabled: () => false,
        passkeyAuthenticator: () async => throw StateError('boom'),
      );
      addTearDown(bloc.close);

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthInProgress>(), isA<AuthFailure>()]),
      );

      bloc.add(const AuthPasskeySubmitted());
    });

    test(
        'flag Off with no authenticator wired still emits AuthAuthenticated (today\'s fallback)',
        () async {
      final bloc = AuthBloc(isPasskeySimulatorEnabled: () => false);
      addTearDown(bloc.close);

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthInProgress>(), isA<AuthAuthenticated>()]),
      );

      bloc.add(const AuthPasskeySubmitted());
    });
  });
}
