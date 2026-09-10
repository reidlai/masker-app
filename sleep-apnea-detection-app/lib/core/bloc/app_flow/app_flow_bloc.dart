import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../onboarding/onboarding_gate.dart';
import '../../permissions/ble_permission_service.dart';
import 'app_flow_event.dart';
import 'app_flow_state.dart';

/// Single source of "where the user is", from boot to the tab shell. On
/// construction it resolves the persisted [OnboardingGate]: fresh install →
/// `onboarding` (no sign-in screen); returning user → `loggedOut`. The
/// post-`loggedOut` permission-check orchestration is unchanged.
class AppFlowBloc extends Bloc<AppFlowEvent, AppFlowState> {
  final BlePermissionService _permissionService;
  final OnboardingGate _gate;

  AppFlowBloc({
    BlePermissionService permissionService = const BlePermissionService(),
    OnboardingGate? onboardingGate,
  })  : _permissionService = permissionService,
        _gate = onboardingGate ?? OnboardingGate.instance,
        super(const AppFlowState()) {
    on<AppFlowResolveRequested>(_onResolve);
    on<AppFlowUnregistered>(_onUnregistered);
    on<AppFlowLoginSucceeded>(_onLoginSucceeded);
    on<AppFlowPermissionRetryRequested>(_onRetry);
    on<AppFlowPrimerCompleted>(
      (event, emit) => emit(state.copyWith(stage: AppFlowStage.ready)),
    );
    on<AppFlowLogoutRequested>(
      // Logout keeps the user onboarded (gate stays set) → back to sign-in.
      (event, emit) => emit(state.copyWith(
        stage: AppFlowStage.loggedOut,
        onboardingStep: OnboardingStep.register,
      )),
    );
    on<AppFlowOnboardingStepAdvanced>(_onOnboardingAdvanced);
    on<AppFlowOnboardingStepBack>(_onOnboardingBack);

    add(const AppFlowResolveRequested());
  }

  Future<void> _onResolve(
    AppFlowResolveRequested event,
    Emitter<AppFlowState> emit,
  ) async {
    if (state.stage != AppFlowStage.resolving) return;
    bool done;
    try {
      done = await _gate.isComplete();
    } catch (_) {
      // A read failure must not hang the boot spinner. Fall through as a
      // returning user → the sign-in screen degrades to pre-boot-resolve
      // behaviour (a genuinely-new user still reaches onboarding from there).
      done = true;
    }
    if (isClosed || state.stage != AppFlowStage.resolving) return;
    emit(state.copyWith(
      stage: done ? AppFlowStage.loggedOut : AppFlowStage.onboarding,
      onboardingStep: OnboardingStep.register,
    ));
  }

  Future<void> _onUnregistered(
    AppFlowUnregistered event,
    Emitter<AppFlowState> emit,
  ) async {
    emit(state.copyWith(
      stage: AppFlowStage.resolving,
      onboardingStep: OnboardingStep.register,
    ));
    // Own the flag clear here rather than trusting every dispatch site to do it.
    try {
      await _gate.clear();
    } catch (_) {}
    if (isClosed) return;
    add(const AppFlowResolveRequested());
  }

  static const _steps = [
    OnboardingStep.register,
    OnboardingStep.medicalProfile,
    OnboardingStep.passkeyEnrollment,
  ];

  Future<void> _onOnboardingAdvanced(
    AppFlowOnboardingStepAdvanced event,
    Emitter<AppFlowState> emit,
  ) async {
    if (state.stage != AppFlowStage.onboarding) return;
    final i = _steps.indexOf(state.onboardingStep);
    if (i < 0 || i == _steps.length - 1) {
      // Past the last step → onboarding complete. Persist the flag so the next
      // boot lands on sign-in; a write failure must not trap the user here.
      try {
        await _gate.markComplete();
      } catch (e) {
        // Breadcrumb only — do not trap the user in onboarding on a write fail.
        debugPrint('OnboardingGate.markComplete failed: $e');
      }
      if (isClosed || state.stage != AppFlowStage.onboarding) return;
      emit(state.copyWith(
        stage: AppFlowStage.ready,
        onboardingStep: OnboardingStep.done,
      ));
    } else {
      emit(state.copyWith(onboardingStep: _steps[i + 1]));
    }
  }

  void _onOnboardingBack(
    AppFlowOnboardingStepBack event,
    Emitter<AppFlowState> emit,
  ) {
    if (state.stage != AppFlowStage.onboarding) return;
    final i = _steps.indexOf(state.onboardingStep);
    if (i > 0) emit(state.copyWith(onboardingStep: _steps[i - 1]));
  }

  Future<void> _onLoginSucceeded(
    AppFlowLoginSucceeded event,
    Emitter<AppFlowState> emit,
  ) async {
    // Re-entrancy guard: a duplicate login-success signal (e.g. a stray
    // AuthBloc state emission) must not restart an in-flight or completed
    // check.
    if (state.stage != AppFlowStage.loggedOut) return;

    // A new / just-unregistered user (no profile after hydrate) is routed to
    // the onboarding wizard, not the permission-check path.
    if (event.needsOnboarding) {
      emit(state.copyWith(
        stage: AppFlowStage.onboarding,
        onboardingStep: OnboardingStep.register,
      ));
      return;
    }

    emit(state.copyWith(stage: AppFlowStage.checkingPermission));

    try {
      final status = await _permissionService.checkPermission();
      if (isClosed) return;
      // A logout (or retry) may have moved the flow on while the async
      // permission check was in flight — don't clobber it with a stale result.
      if (state.stage != AppFlowStage.checkingPermission) return;
      emit(state.copyWith(
        stage: status.isGranted
            ? AppFlowStage.ready
            : AppFlowStage.needsPrimer,
      ));
    } catch (_) {
      // Never hang on the spinner forever if the platform channel throws —
      // surface a retry instead.
      if (isClosed || state.stage != AppFlowStage.checkingPermission) return;
      emit(state.copyWith(stage: AppFlowStage.permissionCheckFailed));
    }
  }

  Future<void> _onRetry(
    AppFlowPermissionRetryRequested event,
    Emitter<AppFlowState> emit,
  ) async {
    emit(state.copyWith(stage: AppFlowStage.loggedOut));
    await _onLoginSucceeded(const AppFlowLoginSucceeded(), emit);
  }
}
