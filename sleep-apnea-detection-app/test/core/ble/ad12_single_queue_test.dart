// AD-12 invariant: every bio-signal consumer reads the ONE process-wide
// BehaviorSubject<double> exposed by BleReceiverService — no consumer opens its
// own BLE subscription or instantiates a second queue.
//
// Post-G3: BleBloc, SleepMonitoringBloc and CalibrationBloc all take their
// IBLESensorDriver by constructor DI and consume that one queue.

import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:masker_app/core/ble/ble_receiver_service.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/core/monitoring/drift_and_noise_floor_envelope.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:masker_app/core/bloc/ble/ble_bloc.dart';
import 'package:masker_app/core/bloc/ble/ble_event.dart';
import 'package:masker_app/core/bloc/ble/ble_state.dart';
import 'package:masker_app/core/bloc/calibration/calibration_bloc.dart';
import 'package:masker_app/core/bloc/calibration/calibration_event.dart';
import 'package:masker_app/core/bloc/monitoring/sleep_monitoring_bloc.dart';
import 'package:masker_app/core/bloc/monitoring/sleep_monitoring_event.dart';

void main() {
  group('AD-12 single unified reactive queue', () {
    late BleReceiverService receiver;

    setUp(() {
      receiver = BleReceiverService();
      receiver.resetForTest();
    });

    tearDown(() {
      receiver.dispose();
    });

    test('reactiveStream is a single ValueStream shared by every subscriber',
        () async {
      expect(receiver.reactiveStream, isA<ValueStream<double>>());

      final a = <double>[];
      final b = <double>[];
      final subA = receiver.signalStream.listen(a.add);
      final subB = receiver.signalStream.listen(b.add);

      BleSimulatorDriver().emitSignal(7.7, isSimulator: true);
      BleSimulatorDriver().emitSignal(1.1, isSimulator: true);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(a, containsAllInOrder([7.7, 1.1]));
      expect(b, equals(a));
      // Same latest-value replay for a late subscriber — one queue, not two.
      expect(receiver.reactiveStream.value, equals(1.1));

      await subA.cancel();
      await subB.cancel();
    });

    test('BleBloc consumes the injected receiver queue, not a new subject',
        () async {
      final bloc = BleBloc(telemetryService: receiver);
      addTearDown(bloc.close);

      bloc.add(const BleStartTelemetryRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      BleSimulatorDriver().emitSignal(4.2, isSimulator: true);
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(bloc.state, isA<BleTelemetryActiveState>());
      final state = bloc.state as BleTelemetryActiveState;
      expect(state.currentSignal, equals(4.2));
      // The value travelled sensor-driver -> the ONE receiver queue -> BleBloc.
      expect(receiver.reactiveStream.value, equals(4.2));
      expect(state.isSimulatorMode, isTrue);
    });

    test('a subscription taken before a driver swap keeps receiving (AD-12)',
        () async {
      final seen = <double>[];
      final sub = receiver.signalStream.listen(seen.add);

      BleSimulatorDriver().emitSignal(2.0, isSimulator: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // AD-11 swap — consumers must NOT have to re-subscribe.
      receiver.setActiveDriver(BleSimulatorDriver());

      BleSimulatorDriver().emitSignal(9.0, isSimulator: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(seen, containsAllInOrder([2.0, 9.0]));
      expect(receiver.reactiveStream.value, equals(9.0));

      await sub.cancel();
    });

    test(
        'BleBloc + SleepMonitoringBloc + CalibrationBloc all read the ONE '
        'receiver queue — a single push reaches every consumer', () async {
      final bleBloc = BleBloc(telemetryService: receiver);
      final monBloc = SleepMonitoringBloc(
        driver: receiver,
        permissionService: const BlePermissionService(),
        isDevMode: true,
      );
      final calBloc = CalibrationBloc(bleDriver: receiver);
      addTearDown(() async {
        await bleBloc.close();
        await monBloc.close();
        await calBloc.close();
      });

      // A raw subscription standing in for "one more consumer of the queue".
      final queueSeen = <double>[];
      final qsub = receiver.signalStream.listen(queueSeen.add);

      // BleBloc telemetry subscription.
      bleBloc.add(const BleStartTelemetryRequested());

      // SleepMonitoringBloc: dev-mode connect, then a live monitoring session
      // (wide band so the spike does not trip an alarm).
      monBloc.add(const SleepMonitoringStarted());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      monBloc.add(const SleepMonitoringCalibrationCompleted(
          IdleBand(lower: -1e6, upper: 1e6)));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      monBloc.add(const SleepMonitoringSessionStarted());

      // CalibrationBloc: idle-sample live readout subscription.
      calBloc.add(const CalibrationIdleSampleStarted());
      await Future<void>.delayed(const Duration(milliseconds: 40));

      // Exactly one push into the single simulator driver behind the queue.
      BleSimulatorDriver().emitSignal(4242.0, isSimulator: true);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // That single push travelled through the ONE BehaviorSubject and reached
      // every consumer — no consumer has its own second queue.
      expect(queueSeen, contains(4242.0));
      expect(monBloc.state.recentSignalBuffer, contains(4242.0));
      expect(calBloc.state.liveBand, isNotNull);
      expect(calBloc.state.liveBand!.upper, greaterThanOrEqualTo(4242.0));

      // BleBloc is driven by that same queue's traffic.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(bleBloc.state, isA<BleTelemetryActiveState>());

      await qsub.cancel();
    });
  });
}
