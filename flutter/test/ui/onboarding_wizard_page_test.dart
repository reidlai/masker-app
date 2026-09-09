import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_bloc.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_event.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_state.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:masker_app/core/profile/user_profile.dart';
import 'package:masker_app/core/profile/user_profile_service.dart';
import 'package:masker_app/ui/pages/onboarding_wizard_page.dart';

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

Future<AppFlowBloc> _pumpAtOnboarding(WidgetTester tester) async {
  final bloc = AppFlowBloc(permissionService: const _GrantedPermissionService());
  addTearDown(bloc.close);
  bloc.add(const AppFlowLoginSucceeded(needsOnboarding: true));
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

void main() {
  setUp(() {
    ProfileRepository.instance = SimulatedProfileRepository(latency: Duration.zero);
    UserProfileService.instance.reset();
  });
  tearDown(ProfileRepository.reset);

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

  testWidgets('walk to ready: register, then Continue through the placeholders', (tester) async {
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester); // → medicalProfile

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(); // → passkeyEnrollment
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(bloc.state.stage, AppFlowStage.ready);
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

  testWidgets('Back on the medicalProfile step returns to register', (tester) async {
    final bloc = await _pumpAtOnboarding(tester);
    await _completeRegister(tester); // → medicalProfile

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(bloc.state.onboardingStep, OnboardingStep.register);
    expect(find.byKey(const Key('onboarding-consent-checkbox')), findsOneWidget);
  });
}
