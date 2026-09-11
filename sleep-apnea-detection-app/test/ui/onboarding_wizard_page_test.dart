import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_bloc.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_state.dart';
import 'package:masker_app/core/bloc/auth/auth_state.dart'
    show passkeyUnavailableMessage;
import 'package:masker_app/core/config/passkey_simulator_config.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/onboarding/onboarding_gate.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:masker_app/core/profile/user_profile.dart';
import 'package:masker_app/core/profile/user_profile_service.dart';
import 'package:masker_app/ui/pages/onboarding_wizard_page.dart';

/// Onboarding not complete → `AppFlowBloc` resolves straight to the wizard.
class _IncompleteOnboardingGate implements OnboardingGate {
  @override
  Future<bool> isComplete() async => false;
  @override
  Future<void> markComplete() async {}
  @override
  Future<void> clear() async {}
}

class _GrantedPermissionService extends BlePermissionService {
  const _GrantedPermissionService();
  @override
  Future<BlePermissionStatus> checkPermission() async =>
      const BlePermissionStatus(BlePermissionResult.granted, []);
}

class _RegisterThrowsRepository extends SimulatedProfileRepository {
  _RegisterThrowsRepository() : super(latency: Duration.zero);
  @override
  Future<UserProfile> registerUser() async => throw Exception('network');
}

class _CountingRegisterRepository extends SimulatedProfileRepository {
  _CountingRegisterRepository()
      : super(latency: const Duration(milliseconds: 200));
  int calls = 0;
  @override
  Future<UserProfile> registerUser() {
    calls++;
    return super.registerUser();
  }
}

/// `registerUser()` works (needed to reach step 2); `saveUserProfile()` throws.
class _SaveThrowsRepository extends SimulatedProfileRepository {
  _SaveThrowsRepository() : super(latency: Duration.zero);
  @override
  Future<void> saveUserProfile(UserProfile profile) async =>
      throw Exception('network');
}

/// Register + save work (needed to reach step 3); `enrollPasskey()` throws.
class _EnrollThrowsRepository extends SimulatedProfileRepository {
  _EnrollThrowsRepository() : super(latency: Duration.zero);
  @override
  Future<UserProfile> enrollPasskey() async =>
      throw Exception('biometric cancelled');
}

class _CountingEnrollRepository extends SimulatedProfileRepository {
  _CountingEnrollRepository()
      : super(latency: const Duration(milliseconds: 200));
  int calls = 0;
  @override
  Future<UserProfile> enrollPasskey() {
    calls++;
    return super.enrollPasskey();
  }
}

Future<AppFlowBloc> _pumpAtOnboarding(WidgetTester tester) async {
  // The Medical Profile step is a tall scrolling form; give it room so its
  // "Save & Continue" button is on-screen and tappable.
  await tester.binding.setSurfaceSize(const Size(1000, 2600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final bloc = AppFlowBloc(
    permissionService: const _GrantedPermissionService(),
    onboardingGate: _IncompleteOnboardingGate(),
  );
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AppFlowBloc>.value(
        value: bloc,
        child: const OnboardingWizardPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

Future<void> _completeRegister(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('onboarding-consent-checkbox')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('onboarding-create-account')));
  await tester.pumpAndSettle();
}

/// Fill the Medical Profile step with valid values and submit. Assumes the
/// wizard is already on step 2 (call after [_completeRegister]).
Future<void> _completeMedicalProfile(WidgetTester tester) async {
  final f = find.byType(EditableText);
  await tester.enterText(f.at(0), 'Dana Scully');
  await tester.enterText(f.at(1), 'dana.scully@example.com');
  await tester.enterText(f.at(2), '(555) 111-2222');
  await tester.enterText(f.at(3), '42');
  await tester.enterText(f.at(4), '68');
  await tester.enterText(f.at(5), '170');
  await tester.enterText(f.at(6), 'Fox Mulder');
  await tester.enterText(f.at(7), '(555) 333-4444');
  await tester.ensureVisible(find.text('Save & Continue'));
  await tester.tap(find.text('Save & Continue'));
  await tester.pumpAndSettle();
}

/// Tap "Create Passkey" on step 3. Assumes the wizard is on `passkeyEnrollment`.
Future<void> _completePasskey(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('onboarding-create-passkey')));
  await tester.tap(find.byKey(const Key('onboarding-create-passkey')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ProfileRepository.instance = SimulatedProfileRepository(latency: Duration.zero);
    UserProfileService.instance.reset();
    PasskeySimulatorConfig.instance.reset(); // process-global singleton
  });
  tearDown(() {
    ProfileRepository.reset();
    PasskeySimulatorConfig.instance.reset();
  });

  testWidgets('register step: consent + disabled Create account, no Continue/Back', (tester) async {
    await _pumpAtOnboarding(tester);

    expect(find.byKey(const Key('onboarding-step-register')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-consent-checkbox')), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Back'), findsNothing);

    final btn = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const Key('onboarding-create-account')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(btn.onPressed, isNull); // disabled until consent
  });

  testWidgets('consent + Create account registers and advances to medicalProfile', (tester) async {
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester);

    expect(bloc.state.onboardingStep, OnboardingStep.medicalProfile);
    expect(UserProfileService.instance.current, isNotNull);
    expect(UserProfileService.instance.current!.userId, isNotEmpty);
    expect(find.byKey(const Key('onboarding-step-medicalProfile')), findsOneWidget);
  });

  testWidgets('registerUser failure shows an inline error and stays on register', (tester) async {
    ProfileRepository.instance = _RegisterThrowsRepository();
    final bloc = await _pumpAtOnboarding(tester);

    await tester.tap(find.byKey(const Key('onboarding-consent-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-create-account')));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't create your account — try again."), findsOneWidget);
    expect(bloc.state.onboardingStep, OnboardingStep.register);
    expect(UserProfileService.instance.current, isNull);
  });

  testWidgets('walk to ready: register, medical profile, passkey', (tester) async {
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester); // → medicalProfile
    await _completeMedicalProfile(tester); // → passkeyEnrollment
    expect(find.byKey(const Key('onboarding-create-passkey')), findsOneWidget);

    await _completePasskey(tester); // → ready / done
    // In the real app `main` swaps to MainContainerPage here; this test tree
    // keeps OnboardingWizardPage mounted, so assert on the bloc, not the UI.
    expect(bloc.state.stage, AppFlowStage.ready);
    expect(bloc.state.onboardingStep, OnboardingStep.done);
  });

  testWidgets('passkey step: Create Passkey only — no Back / Finish / Continue', (tester) async {
    await _pumpAtOnboarding(tester);
    await _completeRegister(tester);
    await _completeMedicalProfile(tester); // → passkeyEnrollment

    expect(find.byKey(const Key('onboarding-step-passkeyEnrollment')), findsOneWidget);
    expect(find.text('Set up your account  3/3'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-create-passkey')), findsOneWidget);
    expect(find.textContaining('Simulated enrollment'), findsOneWidget); // flag defaults ON in tests
    expect(find.text('Back'), findsNothing);
    expect(find.text('Finish'), findsNothing);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('Create Passkey records a credential id and reaches ready', (tester) async {
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester);
    await _completeMedicalProfile(tester);
    await _completePasskey(tester);

    expect(bloc.state.stage, AppFlowStage.ready);
    expect(bloc.state.onboardingStep, OnboardingStep.done);
    expect(UserProfileService.instance.current!.passkeyCredentialId, isNotEmpty);
  });

  testWidgets('enrollPasskey failure shows an inline retry and does not advance', (tester) async {
    ProfileRepository.instance = _EnrollThrowsRepository();
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester);
    await _completeMedicalProfile(tester);
    await _completePasskey(tester);

    expect(find.text("Couldn't create your passkey — try again."), findsOneWidget);
    expect(bloc.state.onboardingStep, OnboardingStep.passkeyEnrollment);
    expect(bloc.state.stage, AppFlowStage.onboarding);
  });

  testWidgets(
      'passkey step, simulator off: shows the unavailable copy and Create Passkey is blocked',
      (tester) async {
    PasskeySimulatorConfig.instance.setEnabled(false);
    final repo = _CountingEnrollRepository();
    ProfileRepository.instance = repo;

    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester);
    await _completeMedicalProfile(tester); // → passkeyEnrollment

    // Resting copy is the "not wired up" line, not a biometric prompt.
    expect(find.textContaining("isn't wired up in this build"), findsOneWidget);
    expect(find.textContaining('Simulated enrollment'), findsNothing);

    // Tapping "Create Passkey" surfaces the shared unavailable message, calls
    // no repo, and does not advance the wizard.
    await _completePasskey(tester);
    expect(find.text(passkeyUnavailableMessage), findsOneWidget);
    expect(repo.calls, 0);
    expect(bloc.state.stage, AppFlowStage.onboarding);
    expect(bloc.state.onboardingStep, OnboardingStep.passkeyEnrollment);
  });

  testWidgets('a second tap while enrolling is ignored (one enrollPasskey call)', (tester) async {
    final repo = _CountingEnrollRepository();
    ProfileRepository.instance = repo;
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester);
    await _completeMedicalProfile(tester);

    await tester.tap(find.byKey(const Key('onboarding-create-passkey')));
    await tester.pump(const Duration(milliseconds: 50)); // in flight
    await tester.tap(find.byKey(const Key('onboarding-create-passkey'))); // ignored
    await tester.pumpAndSettle();

    expect(repo.calls, 1);
    expect(bloc.state.stage, AppFlowStage.ready);
  });

  testWidgets('medical profile step: form shows, no tick, no generic Continue/Back', (tester) async {
    await _pumpAtOnboarding(tester);
    await _completeRegister(tester); // → medicalProfile

    expect(find.byKey(const Key('onboarding-step-medicalProfile')), findsOneWidget);
    expect(find.text('Set up your account  2/3'), findsOneWidget); // still step 2/3
    expect(find.text('Patient Identification (HIPAA Level 1 PHI)'), findsOneWidget);
    expect(find.text('Save & Continue'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Back'), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('valid profile saves and advances to passkeyEnrollment with no success snackbar', (tester) async {
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester);
    await _completeMedicalProfile(tester);

    expect(bloc.state.onboardingStep, OnboardingStep.passkeyEnrollment);
    expect(UserProfileService.instance.current!.fullName, 'Dana Scully');
    expect(UserProfileService.instance.current!.email, 'dana.scully@example.com');
    expect(find.text('Medical profile saved ✓'), findsNothing);
  });

  testWidgets('invalid profile is blocked: inline error, stays on medicalProfile', (tester) async {
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester); // → medicalProfile, empty form

    await tester.ensureVisible(find.text('Save & Continue'));
    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(bloc.state.onboardingStep, OnboardingStep.medicalProfile);
  });

  testWidgets('a save-write failure shows the error snackbar and does not advance', (tester) async {
    ProfileRepository.instance = _SaveThrowsRepository();
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester);
    await _completeMedicalProfile(tester);

    expect(find.text("Couldn't save — try again."), findsOneWidget);
    expect(bloc.state.onboardingStep, OnboardingStep.medicalProfile);
  });

  testWidgets('a second tap while registering is ignored (one registerUser call)', (tester) async {
    final repo = _CountingRegisterRepository();
    ProfileRepository.instance = repo;
    final bloc = await _pumpAtOnboarding(tester);

    await tester.tap(find.byKey(const Key('onboarding-consent-checkbox')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-create-account')));
    await tester.pump(const Duration(milliseconds: 50)); // in flight
    await tester.tap(find.byKey(const Key('onboarding-create-account'))); // ignored
    await tester.pumpAndSettle();

    expect(repo.calls, 1);
    expect(bloc.state.onboardingStep, OnboardingStep.medicalProfile);
  });

}
