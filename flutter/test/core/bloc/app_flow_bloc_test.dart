import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_bloc.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_event.dart';
import 'package:masker_app/core/bloc/app_flow/app_flow_state.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';

class _FakePermissionService extends BlePermissionService {
  final BlePermissionStatus status;
  int calls = 0;
  _FakePermissionService(this.status);

  @override
  Future<BlePermissionStatus> checkPermission() async {
    calls++;
    return status;
  }
}

class _ThrowsOncePermissionService extends BlePermissionService {
  bool thrown = false;

  @override
  Future<BlePermissionStatus> checkPermission() async {
    if (!thrown) {
      thrown = true;
      throw Exception('platform channel unavailable');
    }
    return const BlePermissionStatus(BlePermissionResult.granted, []);
  }
}

void main() {
  test('initial stage is loggedOut', () {
    final bloc = AppFlowBloc();
    expect(bloc.state.stage, AppFlowStage.loggedOut);
    bloc.close();
  });

  blocTest<AppFlowBloc, AppFlowState>(
    'login with permission already granted goes checkingPermission -> ready',
    build: () => AppFlowBloc(
      permissionService: _FakePermissionService(
        const BlePermissionStatus(BlePermissionResult.granted, []),
      ),
    ),
    act: (bloc) => bloc.add(const AppFlowLoginSucceeded()),
    expect: () => const [
      AppFlowState(stage: AppFlowStage.checkingPermission),
      AppFlowState(stage: AppFlowStage.ready),
    ],
  );

  blocTest<AppFlowBloc, AppFlowState>(
    'login with permission not granted routes through the primer',
    build: () => AppFlowBloc(
      permissionService: _FakePermissionService(
        const BlePermissionStatus(
            BlePermissionResult.denied, ['Bluetooth Scan']),
      ),
    ),
    act: (bloc) => bloc.add(const AppFlowLoginSucceeded()),
    expect: () => const [
      AppFlowState(stage: AppFlowStage.checkingPermission),
      AppFlowState(stage: AppFlowStage.needsPrimer),
    ],
  );

  blocTest<AppFlowBloc, AppFlowState>(
    'a duplicate login-success signal is ignored while not loggedOut',
    build: () => AppFlowBloc(
      permissionService: _FakePermissionService(
        const BlePermissionStatus(BlePermissionResult.granted, []),
      ),
    ),
    act: (bloc) => bloc
      ..add(const AppFlowLoginSucceeded())
      ..add(const AppFlowLoginSucceeded()),
    expect: () => const [
      AppFlowState(stage: AppFlowStage.checkingPermission),
      AppFlowState(stage: AppFlowStage.ready),
    ],
  );

  blocTest<AppFlowBloc, AppFlowState>(
    'a throwing permission check surfaces permissionCheckFailed, then Retry recovers',
    build: () => AppFlowBloc(permissionService: _ThrowsOncePermissionService()),
    act: (bloc) async {
      bloc.add(const AppFlowLoginSucceeded());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const AppFlowPermissionRetryRequested());
    },
    expect: () => const [
      AppFlowState(stage: AppFlowStage.checkingPermission),
      AppFlowState(stage: AppFlowStage.permissionCheckFailed),
      AppFlowState(stage: AppFlowStage.loggedOut),
      AppFlowState(stage: AppFlowStage.checkingPermission),
      AppFlowState(stage: AppFlowStage.ready),
    ],
  );

  blocTest<AppFlowBloc, AppFlowState>(
    'PrimerCompleted advances needsPrimer -> ready',
    build: () => AppFlowBloc(
      permissionService: _FakePermissionService(
        const BlePermissionStatus(BlePermissionResult.denied, ['Bluetooth']),
      ),
    ),
    act: (bloc) async {
      bloc.add(const AppFlowLoginSucceeded());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const AppFlowPrimerCompleted());
    },
    skip: 2,
    expect: () => const [
      AppFlowState(stage: AppFlowStage.ready),
    ],
  );
}
