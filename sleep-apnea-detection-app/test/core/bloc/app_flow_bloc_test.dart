import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_bloc.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_event.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_state.dart';
import 'package:masker_app/core/onboarding/onboarding_gate.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';

class _GrantedPermissionService extends BlePermissionService {
  const _GrantedPermissionService();
  @override
  Future<BlePermissionStatus> checkPermission() async =>
      const BlePermissionStatus(BlePermissionResult.granted, []);
}

class _SlowGrantedPermissionService extends BlePermissionService {
  const _SlowGrantedPermissionService();
  @override
  Future<BlePermissionStatus> checkPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const BlePermissionStatus(BlePermissionResult.granted, []);
  }
}

class _FakeOnboardingGate implements OnboardingGate {
  _FakeOnboardingGate({
    this.complete = true,
    this.throwOnMarkComplete = false,
    this.throwOnIsComplete = false,
  });
  bool complete;
  final bool throwOnMarkComplete;
  final bool throwOnIsComplete;
  int markCompleteCalls = 0;
  int clearCalls = 0;

  @override
  Future<bool> isComplete() async {
    if (throwOnIsComplete) throw Exception('prefs read failed');
    return complete;
  }
  @override
  Future<void> markComplete() async {
    markCompleteCalls++;
    if (throwOnMarkComplete) throw Exception('prefs write failed');
    complete = true;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    complete = false;
  }
}

({AppFlowBloc bloc, _FakeOnboardingGate gate}) build({
  bool complete = true,
  bool throwOnMarkComplete = false,
  bool throwOnIsComplete = false,
  BlePermissionService perm = const _GrantedPermissionService(),
}) {
  final gate = _FakeOnboardingGate(
    complete: complete,
    throwOnMarkComplete: throwOnMarkComplete,
    throwOnIsComplete: throwOnIsComplete,
  );
  return (
    bloc: AppFlowBloc(permissionService: perm, onboardingGate: gate),
    gate: gate,
  );
}

/// Wait for the boot-time resolve to settle out of [AppFlowStage.resolving].
Future<AppFlowState> resolved(AppFlowBloc bloc) async {
  if (bloc.state.stage != AppFlowStage.resolving) return bloc.state;
  return bloc.stream.firstWhere((s) => s.stage != AppFlowStage.resolving);
}

void main() {
  group('boot resolve', () {
    test('gate incomplete → onboarding/register, sign-in screen skipped',
        () async {
      final r = build(complete: false);
      addTearDown(r.bloc.close);

      final s = await resolved(r.bloc);
      expect(s.stage, AppFlowStage.onboarding);
      expect(s.onboardingStep, OnboardingStep.register);
    });

    test('gate complete → loggedOut', () async {
      final r = build(complete: true);
      addTearDown(r.bloc.close);

      expect((await resolved(r.bloc)).stage, AppFlowStage.loggedOut);
    });

    test('resolve is idempotent — a second AppFlowResolveRequested is a no-op',
        () async {
      final r = build(complete: true);
      addTearDown(r.bloc.close);
      await resolved(r.bloc); // → loggedOut

      r.bloc.add(const AppFlowResolveRequested());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(r.bloc.state.stage, AppFlowStage.loggedOut);
    });

    test('a gate read failure falls through to loggedOut, never hangs', () async {
      final r = build(throwOnIsComplete: true);
      addTearDown(r.bloc.close);

      final s = await resolved(r.bloc);
      expect(s.stage, AppFlowStage.loggedOut);
    });

    test('boot straight into the wizard walks to ready and marks the gate',
        () async {
      final r = build(complete: false);
      addTearDown(r.bloc.close);
      final s = await resolved(r.bloc);
      expect(s.stage, AppFlowStage.onboarding); // no login step in between

      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere(
          (s) => s.onboardingStep == OnboardingStep.medicalProfile);
      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere(
          (s) => s.onboardingStep == OnboardingStep.passkeyEnrollment);
      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.ready);

      expect(r.gate.markCompleteCalls, 1);
    });
  });

  test('AppFlowLogoutRequested returns the flow to loggedOut', () async {
    final r = build();
    addTearDown(r.bloc.close);
    await resolved(r.bloc);

    r.bloc.add(const AppFlowLoginSucceeded());
    await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.ready);

    r.bloc.add(const AppFlowLogoutRequested());
    await expectLater(
      r.bloc.stream,
      emits(predicate<AppFlowState>((s) => s.stage == AppFlowStage.loggedOut)),
    );
  });

  test('login works again after logout (re-entrancy guard passes)', () async {
    final r = build();
    addTearDown(r.bloc.close);
    await resolved(r.bloc);

    r.bloc.add(const AppFlowLoginSucceeded());
    await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.ready);
    r.bloc.add(const AppFlowLogoutRequested());
    await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.loggedOut);

    r.bloc.add(const AppFlowLoginSucceeded());
    await expectLater(
      r.bloc.stream,
      emitsThrough(
          predicate<AppFlowState>((s) => s.stage == AppFlowStage.ready)),
    );
  });

  test(
      'logout during an in-flight permission check is not clobbered by its result',
      () async {
    final r = build(perm: const _SlowGrantedPermissionService());
    addTearDown(r.bloc.close);
    await resolved(r.bloc);

    r.bloc.add(const AppFlowLoginSucceeded());
    await r.bloc.stream
        .firstWhere((s) => s.stage == AppFlowStage.checkingPermission);

    r.bloc.add(const AppFlowLogoutRequested());
    await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.loggedOut);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(r.bloc.state.stage, AppFlowStage.loggedOut);
  });

  test('AppFlowUnregistered clears the gate itself and re-resolves to the wizard',
      () async {
    final r = build(complete: true);
    addTearDown(r.bloc.close);
    await resolved(r.bloc); // → loggedOut

    r.bloc.add(const AppFlowUnregistered());

    await expectLater(
      r.bloc.stream,
      emitsThrough(predicate<AppFlowState>((s) =>
          s.stage == AppFlowStage.onboarding &&
          s.onboardingStep == OnboardingStep.register)),
    );
    expect(r.gate.clearCalls, 1);
  });

  group('onboarding', () {
    test('login with needsOnboarding routes to the wizard at step register',
        () async {
      final r = build();
      addTearDown(r.bloc.close);
      await resolved(r.bloc);

      r.bloc.add(const AppFlowLoginSucceeded(needsOnboarding: true));
      await expectLater(
        r.bloc.stream,
        emits(predicate<AppFlowState>((s) =>
            s.stage == AppFlowStage.onboarding &&
            s.onboardingStep == OnboardingStep.register)),
      );
    });

    test('Advance walks the steps, marks the gate, then transitions to ready',
        () async {
      final r = build();
      addTearDown(r.bloc.close);
      await resolved(r.bloc);
      r.bloc.add(const AppFlowLoginSucceeded(needsOnboarding: true));
      await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.onboarding);

      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere(
          (s) => s.onboardingStep == OnboardingStep.medicalProfile);
      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere(
          (s) => s.onboardingStep == OnboardingStep.passkeyEnrollment);
      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.ready);

      expect(r.bloc.state.onboardingStep, OnboardingStep.done);
      expect(r.gate.markCompleteCalls, 1);
    });

    test('a gate-write failure still reaches ready', () async {
      final r = build(throwOnMarkComplete: true);
      addTearDown(r.bloc.close);
      await resolved(r.bloc);
      r.bloc.add(const AppFlowLoginSucceeded(needsOnboarding: true));
      await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.onboarding);

      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere(
          (s) => s.onboardingStep == OnboardingStep.medicalProfile);
      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere(
          (s) => s.onboardingStep == OnboardingStep.passkeyEnrollment);
      r.bloc.add(const AppFlowOnboardingStepAdvanced());

      await expectLater(
        r.bloc.stream,
        emitsThrough(
            predicate<AppFlowState>((s) => s.stage == AppFlowStage.ready)),
      );
      expect(r.gate.markCompleteCalls, 1);
    });

    test('Back retreats a step; no-op on the first step', () async {
      final r = build();
      addTearDown(r.bloc.close);
      await resolved(r.bloc);
      r.bloc.add(const AppFlowLoginSucceeded(needsOnboarding: true));
      await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.onboarding);
      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere(
          (s) => s.onboardingStep == OnboardingStep.medicalProfile);

      r.bloc.add(const AppFlowOnboardingStepBack());
      await r.bloc.stream
          .firstWhere((s) => s.onboardingStep == OnboardingStep.register);

      r.bloc.add(const AppFlowOnboardingStepBack()); // no-op on first step
      r.bloc.add(const AppFlowOnboardingStepAdvanced()); // observable follow-up
      await r.bloc.stream.firstWhere(
          (s) => s.onboardingStep == OnboardingStep.medicalProfile);
      expect(r.bloc.state.onboardingStep, OnboardingStep.medicalProfile);
    });

    test('logout mid-onboarding resets stage and step', () async {
      final r = build();
      addTearDown(r.bloc.close);
      await resolved(r.bloc);
      r.bloc.add(const AppFlowLoginSucceeded(needsOnboarding: true));
      await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.onboarding);
      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await r.bloc.stream.firstWhere(
          (s) => s.onboardingStep == OnboardingStep.medicalProfile);

      r.bloc.add(const AppFlowLogoutRequested());
      await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.loggedOut);
      expect(r.bloc.state.onboardingStep, OnboardingStep.register);
    });

    test('step events are ignored outside the onboarding stage', () async {
      final r = build();
      addTearDown(r.bloc.close);
      await resolved(r.bloc);
      r.bloc.add(const AppFlowLoginSucceeded()); // returning user → ready
      await r.bloc.stream.firstWhere((s) => s.stage == AppFlowStage.ready);

      r.bloc.add(const AppFlowOnboardingStepAdvanced());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(r.bloc.state.stage, AppFlowStage.ready);
      expect(r.bloc.state.onboardingStep, OnboardingStep.register);
    });
  });
}
