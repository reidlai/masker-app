import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_bloc.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_event.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_state.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:masker_app/ui/pages/onboarding_wizard_page.dart';

class _GrantedPermissionService extends BlePermissionService {
  const _GrantedPermissionService();
  @override
  Future<BlePermissionStatus> checkPermission() async =>
      const BlePermissionStatus(BlePermissionResult.granted, []);
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

void main() {
  testWidgets('starts at register — Continue, no Back, "1/3"', (tester) async {
    await _pumpAtOnboarding(tester);

    expect(find.byKey(const Key('onboarding-step-register')), findsOneWidget);
    expect(find.text('Set up your account  1/3'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Back'), findsNothing);
  });

  testWidgets('Continue advances the step; Back retreats it', (tester) async {
    final bloc = await _pumpAtOnboarding(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(bloc.state.onboardingStep, OnboardingStep.medicalProfile);
    expect(find.byKey(const Key('onboarding-step-medicalProfile')), findsOneWidget);
    expect(find.text('Set up your account  2/3'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(bloc.state.onboardingStep, OnboardingStep.register);
    expect(find.byKey(const Key('onboarding-step-register')), findsOneWidget);
  });

  testWidgets('the last step shows Finish; completing it moves the flow to ready', (tester) async {
    final bloc = await _pumpAtOnboarding(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Finish'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-step-passkeyEnrollment')), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(bloc.state.stage, AppFlowStage.ready);
  });
}
