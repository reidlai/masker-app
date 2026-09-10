import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/auth/auth_bloc.dart';
import 'package:masker_app/core/bloc/auth/auth_state.dart';
import 'package:masker_app/core/config/passkey_simulator_config.dart';
import 'package:masker_app/ui/organisms/passkey_auth_card_organism.dart';
import 'package:masker_app/ui/organisms/security_badge_organism.dart';
import 'package:masker_app/ui/pages/login_page.dart';

const _kSwitchKey = Key('passkey-simulator-switch-login');
const _kCaptionKey = Key('passkey-sim-caption');
const _kCaption = 'Simulated authentication — not real FIDO2';

/// Lets a test drive [AuthState] directly, with no timers / rxdart transformer
/// (`throttleTime().switchMap()`) in play — the transformer is subscribed at
/// construction, and awaiting `Bloc.close()` from `addTearDown` (outside any
/// `pump`) never resolves under the widget test's fake-async zone.
class _ProbeAuthBloc extends AuthBloc {
  void push(AuthState state) => emit(state);
}

void main() {
  // PasskeySimulatorConfig is a process-global singleton; keep tests isolated.
  setUp(() => PasskeySimulatorConfig.instance.reset());
  tearDown(() => PasskeySimulatorConfig.instance.reset());

  Future<void> pumpLogin(
    WidgetTester tester, {
    bool? debuggingEnabled,
    bool? developerEnabled,
    AuthBloc? authBloc,
    VoidCallback? onLoginSuccess,
  }) {
    return tester.pumpWidget(
      BlocProvider<AuthBloc>(
        create: (_) =>
            authBloc ??
            AuthBloc(
              passkeyAuthenticator: () async {
                await Future.delayed(const Duration(milliseconds: 50));
              },
            ),
        child: MaterialApp(
          home: LoginPage(
            onLoginSuccess: onLoginSuccess ?? () {},
            debuggingEnabled: debuggingEnabled,
            developerEnabled: developerEnabled,
          ),
        ),
      ),
    );
  }

  testWidgets(
      'renders Passkey authentication elements and triggers AuthBloc on tap',
      (tester) async {
    var loginSuccessTriggered = false;
    await pumpLogin(tester, onLoginSuccess: () => loginSuccessTriggered = true);

    expect(find.text('D-BAND Sleep Apnea Detection App'), findsOneWidget);
    expect(find.text('Biometric Passkey Required'), findsOneWidget);

    final passkeyBtn = find.text('Sign in with Passkey');
    expect(passkeyBtn, findsOneWidget);

    await tester.tap(passkeyBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(loginSuccessTriggered, isTrue);
  });

  testWidgets('developer gate ON: row renders between the auth card and badge',
      (tester) async {
    await pumpLogin(tester, developerEnabled: true);

    expect(find.text('Passkey Simulator'), findsOneWidget);
    expect(find.byKey(_kSwitchKey), findsOneWidget);

    // Position: after PasskeyAuthCardOrganism, before SecurityBadgeOrganism.
    final cardBottom =
        tester.getBottomLeft(find.byType(PasskeyAuthCardOrganism)).dy;
    final rowTop = tester.getTopLeft(find.byKey(_kSwitchKey)).dy;
    final badgeTop =
        tester.getTopLeft(find.byType(SecurityBadgeOrganism)).dy;
    expect(rowTop, greaterThan(cardBottom));
    expect(rowTop, lessThan(badgeTop));
  });

  testWidgets('developer gate ON via the DEV_MODE seam alone (debug seam false)',
      (tester) async {
    // kDebugMode is true under `flutter test`; force the debug seam off so this
    // exercises the `developerEnabled ?? DEV_MODE` disjunct specifically.
    await pumpLogin(tester, debuggingEnabled: false, developerEnabled: true);

    expect(find.byKey(_kSwitchKey), findsOneWidget);
    expect(find.byKey(_kCaptionKey), findsOneWidget);
  });

  testWidgets(
      'developer gate OFF (both seams false): no row, no switch, no caption',
      (tester) async {
    await pumpLogin(tester, debuggingEnabled: false, developerEnabled: false);

    expect(find.text('Passkey Simulator'), findsNothing);
    expect(find.byKey(_kSwitchKey), findsNothing);
    expect(find.text(_kCaption), findsNothing);
  });

  testWidgets('toggling the switch flips PasskeySimulatorConfig and the caption',
      (tester) async {
    await pumpLogin(tester, developerEnabled: true);

    // Default: enabled + caption visible.
    expect(PasskeySimulatorConfig.instance.isEnabled, isTrue);
    expect(find.text(_kCaption), findsOneWidget);

    await tester.tap(find.byKey(_kSwitchKey));
    await tester.pumpAndSettle();
    expect(PasskeySimulatorConfig.instance.isEnabled, isFalse);
    expect(find.text(_kCaption), findsNothing);

    await tester.tap(find.byKey(_kSwitchKey));
    await tester.pumpAndSettle();
    expect(PasskeySimulatorConfig.instance.isEnabled, isTrue);
    expect(find.text(_kCaption), findsOneWidget);
  });

  testWidgets('Settings-side change is reflected here via the shared singleton',
      (tester) async {
    await pumpLogin(tester, developerEnabled: true);
    expect(find.text(_kCaption), findsOneWidget);

    // Simulates the Settings → Developer row writing the same singleton.
    PasskeySimulatorConfig.instance.setEnabled(false);
    await tester.pump();

    expect(find.text(_kCaption), findsNothing);
    expect(tester.widget<Switch>(find.byKey(_kSwitchKey)).value, isFalse);
  });

  testWidgets('switch disables during AuthInProgress and re-enables after',
      (tester) async {
    // Owned + closed by the BlocProvider during the pumped tree teardown — see
    // _ProbeAuthBloc doc for why there is no addTearDown(bloc.close).
    final bloc = _ProbeAuthBloc();

    await pumpLogin(tester, developerEnabled: true, authBloc: bloc);
    expect(tester.widget<Switch>(find.byKey(_kSwitchKey)).onChanged, isNotNull);

    bloc.push(const AuthInProgress());
    await tester.pump();
    expect(tester.widget<Switch>(find.byKey(_kSwitchKey)).onChanged, isNull);

    bloc.push(AuthFailure('x'));
    await tester.pump();
    expect(tester.widget<Switch>(find.byKey(_kSwitchKey)).onChanged, isNotNull);
  });

  testWidgets('no overflow on a short viewport with the dev row present',
      (tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;

    await pumpLogin(tester, developerEnabled: true);

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets(
      'simulator off + no authenticator: Sign in shows the unavailable message, '
      'the button stays enabled, and a post-throttle tap re-runs the attempt',
      (tester) async {
    var loginSuccessTriggered = false;
    final states = <AuthState>[];
    // Closed by the BlocProvider during the pumped tree teardown — no
    // addTearDown(bloc.close); see _ProbeAuthBloc's doc for why.
    final bloc = AuthBloc(isPasskeySimulatorEnabled: () => false);
    final sub = bloc.stream.listen(states.add);
    addTearDown(sub.cancel);

    await pumpLogin(
      tester,
      authBloc: bloc,
      onLoginSuccess: () => loginSuccessTriggered = true,
    );

    await tester.tap(find.text('Sign in with Passkey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(passkeyUnavailableMessage), findsOneWidget);
    expect(loginSuccessTriggered, isFalse);
    // No dead end: the button is still enabled after AuthUnavailable.
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );

    // A second attempt *after* the 300 ms throttle window genuinely re-runs.
    await tester.pump(const Duration(milliseconds: 350));
    states.clear();
    await tester.tap(find.text('Sign in with Passkey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(states, [isA<AuthInProgress>(), isA<AuthUnavailable>()]);
    expect(find.text(passkeyUnavailableMessage), findsOneWidget);
    expect(loginSuccessTriggered, isFalse);

    // Let the second tap's throttle window elapse so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 350));
  });
}
