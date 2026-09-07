import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/i_ble_sensor_driver.dart';
import 'package:masker_app/core/bloc/monitoring/sleep_monitoring_bloc.dart';
import 'package:masker_app/core/bloc/monitoring/sleep_monitoring_event.dart';
import 'package:masker_app/core/bloc/monitoring/sleep_monitoring_state.dart';
import 'package:masker_app/core/monitoring/drift_and_noise_floor_envelope.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';

class _FakeDriver implements IBLESensorDriver {
  final StreamController<double> signal = StreamController<double>.broadcast();
  bool scanCalled = false;
  bool startCalled = false;
  bool stopCalled = false;
  bool disconnectCalled = false;
  bool connectResult = true;

  void emit(double v) => signal.add(v);
  Future<void> close() => signal.close();

  @override
  Stream<double> get signalStream => signal.stream;
  @override
  SensorMonitoringPhase get currentPhase => SensorMonitoringPhase.idle;
  @override
  Stream<SensorMonitoringPhase> get phaseStream => const Stream.empty();
  @override
  Future<bool> scanAndConnect() async {
    scanCalled = true;
    return connectResult;
  }

  @override
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) async =>
      const IdleBand(lower: 0.20, upper: 0.40);
  @override
  void startMonitoringSession() => startCalled = true;
  @override
  void stopMonitoringSession() => stopCalled = true;
  @override
  void disconnect() => disconnectCalled = true;
}

class _FakePermission extends BlePermissionService {
  BlePermissionStatus status;
  int calls = 0;
  _FakePermission(this.status);

  @override
  Future<BlePermissionStatus> checkPermission() async {
    calls++;
    return status;
  }
}

class _ThrowsOncePermission extends BlePermissionService {
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

const _granted = BlePermissionStatus(BlePermissionResult.granted, []);
const _denied =
    BlePermissionStatus(BlePermissionResult.denied, ['Bluetooth Scan']);

void main() {
  late _FakeDriver driver;

  SleepMonitoringBloc build({
    BlePermissionService? perm,
    bool isDevMode = false,
    Stream<void>? scenarioReset,
    Stream<bool>? simulatorActive,
  }) {
    driver = _FakeDriver();
    return SleepMonitoringBloc(
      driver: driver,
      permissionService: perm ?? _FakePermission(_granted),
      isDevMode: isDevMode,
      scenarioResetStream: scenarioReset,
      simulatorActiveStream: simulatorActive,
    );
  }

  test('initial state is checkingPermission', () {
    final bloc = build();
    expect(bloc.state.status, SleepMonitoringStatus.checkingPermission);
    bloc.close();
  });

  blocTest<SleepMonitoringBloc, SleepMonitoringState>(
    'granted permission -> setup + a BLE connect (isBleConnected true, generation bumped)',
    build: () => build(perm: _FakePermission(_granted)),
    act: (bloc) async {
      bloc.add(const SleepMonitoringStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.status, SleepMonitoringStatus.setup);
      expect(bloc.state.isBleConnected, isTrue);
      expect(bloc.state.connectGeneration, 1);
      expect(driver.scanCalled, isTrue);
    },
  );

  blocTest<SleepMonitoringBloc, SleepMonitoringState>(
    'denied permission -> permissionBlocked, no connect',
    build: () => build(perm: _FakePermission(_denied)),
    act: (bloc) async {
      bloc.add(const SleepMonitoringStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.status, SleepMonitoringStatus.permissionBlocked);
      expect(bloc.state.permissionStatus?.missingPermissionNames,
          ['Bluetooth Scan']);
      expect(driver.scanCalled, isFalse);
    },
  );

  blocTest<SleepMonitoringBloc, SleepMonitoringState>(
    'dev mode bypasses the permission gate and connects',
    build: () => build(perm: _FakePermission(_denied), isDevMode: true),
    act: (bloc) async {
      bloc.add(const SleepMonitoringStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.status, SleepMonitoringStatus.setup);
      expect(bloc.state.isBleConnected, isTrue);
      expect(driver.scanCalled, isTrue);
    },
  );

  blocTest<SleepMonitoringBloc, SleepMonitoringState>(
    'a throwing permission check -> permissionCheckFailed, then Retry recovers',
    build: () => build(perm: _ThrowsOncePermission()),
    act: (bloc) async {
      bloc.add(const SleepMonitoringStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SleepMonitoringPermissionRetried());
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.status, SleepMonitoringStatus.setup);
      expect(bloc.state.isBleConnected, isTrue);
    },
  );

  blocTest<SleepMonitoringBloc, SleepMonitoringState>(
    'calibration hand-off unlocks Start Monitoring',
    build: () => build(perm: _FakePermission(_granted)),
    act: (bloc) async {
      bloc.add(const SleepMonitoringStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SleepMonitoringCalibrationCompleted(
          IdleBand(lower: 0.20, upper: 0.40)));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    },
    verify: (bloc) {
      expect(bloc.state.idleBand, const IdleBand(lower: 0.20, upper: 0.40));
      expect(bloc.state.isCalibrationComplete, isTrue);
      expect(bloc.state.canStartMonitoring, isTrue);
    },
  );

  blocTest<SleepMonitoringBloc, SleepMonitoringState>(
    'session start: monitoring status, driver session started, signal buffer capped at 20',
    build: () => build(perm: _FakePermission(_granted)),
    act: (bloc) async {
      bloc.add(const SleepMonitoringStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SleepMonitoringCalibrationCompleted(
          IdleBand(lower: 0.20, upper: 0.40)));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const SleepMonitoringSessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      for (var i = 0; i < 25; i++) {
        driver.emit(0.30 + i * 0.001);
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.status, SleepMonitoringStatus.monitoring);
      expect(driver.startCalled, isTrue);
      expect(bloc.state.recentSignalBuffer.length, 20);
      expect(bloc.state.latestSignalValue, closeTo(0.30 + 24 * 0.001, 1e-9));
    },
  );

  test('sustained in-band signal raises the Tier-1 alert overlay; I\'m Safe clears it',
      () async {
    final bloc = build(perm: _FakePermission(_granted));
    bloc.add(const SleepMonitoringStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    bloc.add(const SleepMonitoringCalibrationCompleted(
        IdleBand(lower: 0.20, upper: 0.40)));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    bloc.add(const SleepMonitoringSessionStarted());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    // 100 in-band ticks == 10 s flatline -> Tier-1 breach.
    for (var i = 0; i < 110; i++) {
      driver.emit(0.30);
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bloc.state.showAlertOverlay, isTrue);

    bloc.add(const SleepMonitoringPatientSafeAcknowledged());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.showAlertOverlay, isFalse);

    await bloc.close();
    await driver.close();
  });

  blocTest<SleepMonitoringBloc, SleepMonitoringState>(
    'stopping the session returns to setup and stops the driver session',
    build: () => build(perm: _FakePermission(_granted)),
    act: (bloc) async {
      bloc.add(const SleepMonitoringStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SleepMonitoringCalibrationCompleted(
          IdleBand(lower: 0.20, upper: 0.40)));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const SleepMonitoringSessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const SleepMonitoringSessionStopped());
      await Future<void>.delayed(const Duration(milliseconds: 5));
    },
    verify: (bloc) {
      expect(bloc.state.status, SleepMonitoringStatus.setup);
      expect(bloc.state.showAlertOverlay, isFalse);
      expect(driver.stopCalled, isTrue);
    },
  );

  blocTest<SleepMonitoringBloc, SleepMonitoringState>(
    'a simulator scenario change mid-session clears any alert overlay',
    build: () {
      final scenarioReset = StreamController<void>.broadcast();
      addTearDown(scenarioReset.close);
      _scenarioResetCtl = scenarioReset;
      return build(
          perm: _FakePermission(_granted), scenarioReset: scenarioReset.stream);
    },
    act: (bloc) async {
      bloc.add(const SleepMonitoringStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const SleepMonitoringCalibrationCompleted(
          IdleBand(lower: 0.20, upper: 0.40)));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const SleepMonitoringSessionStarted());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      for (var i = 0; i < 110; i++) {
        driver.emit(0.30);
      }
      await Future<void>.delayed(const Duration(milliseconds: 30));
      _scenarioResetCtl.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    },
    verify: (bloc) => expect(bloc.state.showAlertOverlay, isFalse),
  );

  test(
      'a mid-session app resume with permission newly denied does not eject the '
      'actively-monitoring user', () async {
    final perm = _FakePermission(_granted);
    final bloc = build(perm: perm);
    bloc.add(const SleepMonitoringStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    bloc.add(const SleepMonitoringCalibrationCompleted(
        IdleBand(lower: 0.20, upper: 0.40)));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    bloc.add(const SleepMonitoringSessionStarted());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(bloc.state.status, SleepMonitoringStatus.monitoring);

    // The OS revoked Bluetooth while the user slept; the app is resumed.
    perm.status = _denied;
    bloc.add(const SleepMonitoringAppResumed());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.status, SleepMonitoringStatus.monitoring);

    await bloc.close();
    await driver.close();
  });

  // --- simulator toggle drives the BLE connection state (I/O Matrix) ---------

  test('enabling the simulator while not in a session -> setup + isBleConnected '
      'true, no permission prompt', () async {
    final ctl = StreamController<bool>.broadcast();
    addTearDown(ctl.close);
    // Real gate denies — proves the toggle bypasses it, not that it was granted.
    final bloc = build(perm: _FakePermission(_denied), simulatorActive: ctl.stream);
    bloc.add(const SleepMonitoringStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.status, SleepMonitoringStatus.permissionBlocked);
    expect(bloc.state.isBleConnected, isFalse);

    ctl.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.status, SleepMonitoringStatus.setup);
    expect(bloc.state.isBleConnected, isTrue);
    expect(bloc.state.permissionStatus?.isGranted, isTrue);

    await bloc.close();
    await driver.close();
  });

  test('disabling the simulator while not in a session -> real gate re-runs, '
      'isBleConnected false', () async {
    final ctl = StreamController<bool>.broadcast();
    addTearDown(ctl.close);
    final bloc = build(
        perm: _FakePermission(_granted),
        isDevMode: true,
        simulatorActive: ctl.stream);
    bloc.add(const SleepMonitoringStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.isBleConnected, isTrue);
    driver.connectResult = false; // real driver: no hardware

    ctl.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.status, SleepMonitoringStatus.setup);
    expect(bloc.state.isBleConnected, isFalse);

    await bloc.close();
    await driver.close();
  });

  test('a simulator toggle during an active session keeps the session running '
      'and does not reset calibration', () async {
    final ctl = StreamController<bool>.broadcast();
    addTearDown(ctl.close);
    final bloc = build(
        perm: _FakePermission(_granted),
        isDevMode: true,
        simulatorActive: ctl.stream);
    bloc.add(const SleepMonitoringStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    bloc.add(const SleepMonitoringCalibrationCompleted(
        IdleBand(lower: 0.20, upper: 0.40)));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    bloc.add(const SleepMonitoringSessionStarted());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(bloc.state.status, SleepMonitoringStatus.monitoring);
    final gen = bloc.state.connectGeneration;

    ctl.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.status, SleepMonitoringStatus.monitoring);
    expect(bloc.state.idleBand, const IdleBand(lower: 0.20, upper: 0.40));
    expect(bloc.state.connectGeneration, gen);

    await bloc.close();
    await driver.close();
  });

  test('rapid on/off/on toggles each re-run the connect flow (calibration '
      'resets, generation bumps each time)', () async {
    final ctl = StreamController<bool>.broadcast();
    addTearDown(ctl.close);
    final bloc = build(perm: _FakePermission(_granted), simulatorActive: ctl.stream);
    bloc.add(const SleepMonitoringStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final gen0 = bloc.state.connectGeneration; // 1 from the initial connect

    ctl.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 15));
    ctl.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 15));
    ctl.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 15));

    expect(bloc.state.connectGeneration, gen0 + 3);
    expect(bloc.state.idleBand, isNull);
    expect(bloc.state.isCalibrationComplete, isFalse);

    await bloc.close();
    await driver.close();
  });

  test('a redundant same-value simulator emission is a no-op (no connect, no '
      'generation bump)', () async {
    final ctl = StreamController<bool>.broadcast();
    addTearDown(ctl.close);
    final bloc = build(perm: _FakePermission(_granted), simulatorActive: ctl.stream);
    bloc.add(const SleepMonitoringStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final gen = bloc.state.connectGeneration;

    // Same value as the current (off) dev-mode.
    ctl.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 15));

    expect(bloc.state.connectGeneration, gen);
    expect(bloc.state.status, SleepMonitoringStatus.setup);

    await bloc.close();
    await driver.close();
  });

  test('a simulator toggle-off during a session is reconciled when the session '
      'ends: the setup screen reflects the real gate, not the dev stub', () async {
    final ctl = StreamController<bool>.broadcast();
    addTearDown(ctl.close);
    final bloc =
        build(perm: _FakePermission(_granted), isDevMode: true, simulatorActive: ctl.stream);
    bloc.add(const SleepMonitoringStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    bloc.add(const SleepMonitoringCalibrationCompleted(
        IdleBand(lower: 0.20, upper: 0.40)));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    bloc.add(const SleepMonitoringSessionStarted());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(bloc.state.status, SleepMonitoringStatus.monitoring);
    expect(bloc.state.isBleConnected, isTrue); // dev connect

    // Simulator toggled OFF mid-session — the session is kept. The real driver
    // now has no hardware to find.
    driver.connectResult = false;
    ctl.add(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.status, SleepMonitoringStatus.monitoring);

    // End the session → reconcile against the now-off simulator's real gate.
    bloc.add(const SleepMonitoringSessionStopped());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.status, SleepMonitoringStatus.setup);
    expect(bloc.state.isBleConnected, isFalse);

    await bloc.close();
    await driver.close();
  });
}

late StreamController<void> _scenarioResetCtl;
