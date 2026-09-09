import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_bloc.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_event.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_state.dart';
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

void main() {
  test('AppFlowLogoutRequested returns the flow to loggedOut', () async {
    final bloc = AppFlowBloc(permissionService: const _GrantedPermissionService());
    addTearDown(bloc.close);

    bloc.add(const AppFlowLoginSucceeded());
    await bloc.stream.firstWhere((s) => s.stage == AppFlowStage.ready);

    bloc.add(const AppFlowLogoutRequested());
    await expectLater(
      bloc.stream,
      emits(predicate<AppFlowState>((s) => s.stage == AppFlowStage.loggedOut)),
    );
  });

  test('login works again after logout (re-entrancy guard passes)', () async {
    final bloc = AppFlowBloc(permissionService: const _GrantedPermissionService());
    addTearDown(bloc.close);

    bloc.add(const AppFlowLoginSucceeded());
    await bloc.stream.firstWhere((s) => s.stage == AppFlowStage.ready);
    bloc.add(const AppFlowLogoutRequested());
    await bloc.stream.firstWhere((s) => s.stage == AppFlowStage.loggedOut);

    bloc.add(const AppFlowLoginSucceeded());
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<AppFlowState>((s) => s.stage == AppFlowStage.ready)),
    );
  });

  test('logout during an in-flight permission check is not clobbered by its result',
      () async {
    final bloc =
        AppFlowBloc(permissionService: const _SlowGrantedPermissionService());
    addTearDown(bloc.close);

    bloc.add(const AppFlowLoginSucceeded());
    await bloc.stream
        .firstWhere((s) => s.stage == AppFlowStage.checkingPermission);

    bloc.add(const AppFlowLogoutRequested());
    await bloc.stream.firstWhere((s) => s.stage == AppFlowStage.loggedOut);

    // Let the slow check resolve; the stale "granted → ready" must not apply.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(bloc.state.stage, AppFlowStage.loggedOut);
  });
}
