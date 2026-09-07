import 'package:flutter_bloc/flutter_bloc.dart';
import '../../permissions/ble_permission_service.dart';
import 'app_flow_event.dart';
import 'app_flow_state.dart';

/// Single source of "where the user is" between login and the tab shell — the
/// `_AppFlowState` machine + `BlePermissionService` orchestration lifted out of
/// `_MaskerAppState` verbatim. Every branch, guard and copy is unchanged.
class AppFlowBloc extends Bloc<AppFlowEvent, AppFlowState> {
  final BlePermissionService _permissionService;

  AppFlowBloc({
    BlePermissionService permissionService = const BlePermissionService(),
  })  : _permissionService = permissionService,
        super(const AppFlowState()) {
    on<AppFlowLoginSucceeded>(_onLoginSucceeded);
    on<AppFlowPermissionRetryRequested>(_onRetry);
    on<AppFlowPrimerCompleted>(
      (event, emit) => emit(state.copyWith(stage: AppFlowStage.ready)),
    );
  }

  Future<void> _onLoginSucceeded(
    AppFlowLoginSucceeded event,
    Emitter<AppFlowState> emit,
  ) async {
    // Re-entrancy guard: a duplicate login-success signal (e.g. a stray
    // AuthBloc state emission) must not restart an in-flight or completed
    // check.
    if (state.stage != AppFlowStage.loggedOut) return;

    emit(state.copyWith(stage: AppFlowStage.checkingPermission));

    try {
      final status = await _permissionService.checkPermission();
      if (isClosed) return;
      emit(state.copyWith(
        stage: status.isGranted
            ? AppFlowStage.ready
            : AppFlowStage.needsPrimer,
      ));
    } catch (_) {
      // Never hang on the spinner forever if the platform channel throws —
      // surface a retry instead.
      if (isClosed) return;
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
