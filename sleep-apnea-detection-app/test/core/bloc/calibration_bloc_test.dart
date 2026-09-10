import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/i_ble_sensor_driver.dart';
import 'package:masker_app/core/bloc/calibration/calibration_bloc.dart';
import 'package:masker_app/core/bloc/calibration/calibration_event.dart';
import 'package:masker_app/core/bloc/calibration/calibration_state.dart';
import 'package:masker_app/core/monitoring/drift_and_noise_floor_envelope.dart';

/// Minimal [IBLESensorDriver] whose `signalStream` and `sampleIdleBand` result
/// are fully controlled by the test.
class _FakeDriver implements IBLESensorDriver {
  final StreamController<double> signal = StreamController<double>.broadcast();
  int sampleCalls = 0;
  IdleBand bandToReturn = const IdleBand(lower: 0.20, upper: 0.40);
  Object? sampleError;

  void emit(double v) => signal.add(v);
  Future<void> close() => signal.close();

  @override
  Stream<double> get signalStream => signal.stream;
  @override
  SensorMonitoringPhase get currentPhase => SensorMonitoringPhase.idle;
  @override
  Stream<SensorMonitoringPhase> get phaseStream => const Stream.empty();
  @override
  Future<bool> scanAndConnect() async => true;
  @override
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) async {
    sampleCalls++;
    if (sampleError != null) throw sampleError!;
    return bandToReturn;
  }

  @override
  void startMonitoringSession() {}
  @override
  void stopMonitoringSession() {}
  @override
  void disconnect() {}
}

void main() {
  late _FakeDriver driver;

  CalibrationBloc buildBloc() {
    driver = _FakeDriver();
    return CalibrationBloc(bleDriver: driver);
  }

  test('initial state: idleSample step, nothing sampled yet', () {
    final d = _FakeDriver();
    final bloc = CalibrationBloc(bleDriver: d);
    expect(bloc.state, const CalibrationState());
    bloc.close();
    d.close();
  });

  blocTest<CalibrationBloc, CalibrationState>(
    'idle sample succeeds -> advances to wearCheck carrying the learned band',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const CalibrationIdleSampleStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      const CalibrationState(sampling: true),
      const CalibrationState(
        step: CalibrationStep.wearCheck,
        band: IdleBand(lower: 0.20, upper: 0.40),
      ),
    ],
    verify: (bloc) => expect(driver.sampleCalls, 1),
  );

  blocTest<CalibrationBloc, CalibrationState>(
    'a silent stream (sampleIdleBand throws) surfaces idleError, no hung spinner',
    build: () {
      driver = _FakeDriver()..sampleError = StateError('no samples');
      return CalibrationBloc(bleDriver: driver);
    },
    act: (bloc) async {
      bloc.add(const CalibrationIdleSampleStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      const CalibrationState(sampling: true),
      const CalibrationState(idleError: true),
    ],
  );

  blocTest<CalibrationBloc, CalibrationState>(
    'wear check: >=2 strict excursion cycles -> complete',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const CalibrationIdleSampleStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const CalibrationWearCheckStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // Two full cycles: strictly above upper (0.40) then below lower (0.20).
      for (final v in [0.55, 0.05, 0.55, 0.05]) {
        driver.emit(v);
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.step, CalibrationStep.complete);
      expect(bloc.state.band, const IdleBand(lower: 0.20, upper: 0.40));
      expect(driver.sampleCalls, 1, reason: 'wear check must not re-sample');
    },
  );

  test(
      'wear check window elapses with <2 cycles -> wearCheckFailed (not connectionLost)',
      () {
    fakeAsync((async) {
      final d = _FakeDriver();
      final bloc = CalibrationBloc(bleDriver: d);

      bloc.add(const CalibrationIdleSampleStarted());
      async.elapse(const Duration(milliseconds: 20));
      bloc.add(const CalibrationWearCheckStarted());
      async.elapse(const Duration(milliseconds: 10));

      d.emit(0.30); // in-band only — no strict excursion possible
      async.elapse(const Duration(milliseconds: 100));
      expect(bloc.state.validCycles, 0);

      async.elapse(kWearCheckWindow);
      async.flushMicrotasks();

      expect(bloc.state.wearCheckFailed, isTrue);
      expect(bloc.state.wearCheckConnectionLost, isFalse);
      expect(bloc.state.wearCheckRunning, isFalse);

      bloc.close();
      d.close();
    });
  });

  blocTest<CalibrationBloc, CalibrationState>(
    'a stream error during wear check fails it as connection-lost',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const CalibrationIdleSampleStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const CalibrationWearCheckStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      driver.signal.addError(StateError('link dropped'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.wearCheckFailed, isTrue);
      expect(bloc.state.wearCheckConnectionLost, isTrue);
    },
  );
}
