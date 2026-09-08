import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/core/bloc/ble/ble_bloc.dart';
import 'package:masker_app/core/bloc/ble/ble_event.dart';
import 'package:masker_app/core/bloc/ble/ble_state.dart';

void main() {
  group('BleBloc Unit Tests', () {
    late BleSimulatorDriver service;
    late BleBloc bloc;

    setUp(() {
      service = BleSimulatorDriver();
      service.resetForTest();
      bloc = BleBloc(telemetryService: service);
    });

    tearDown(() {
      bloc.close();
      service.resetForTest();
    });

    test('Initial state is BleInitialState', () {
      expect(bloc.state, isA<BleInitialState>());
    });

    test('Subscribes to RxDart telemetry stream and emits battery-throttled BleTelemetryActiveState', () async {
      bloc.add(const BleStartTelemetryRequested());
      await Future.delayed(const Duration(milliseconds: 50));

      service.emitSignal(4.5, isSimulator: true);
      await Future.delayed(const Duration(milliseconds: 250));

      expect(bloc.state, isA<BleTelemetryActiveState>());
      final state = bloc.state as BleTelemetryActiveState;
      expect(state.currentSignal, equals(4.5));
      expect(state.isSimulatorMode, isTrue);
    });

    test('sampleTime(200ms) decimates a fast 10Hz burst to <=2 UI states per 200ms window', () async {
      final emitted = <BleState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const BleStartTelemetryRequested());
      await Future.delayed(const Duration(milliseconds: 20));

      // 10 distinct samples ~10ms apart (~100ms of a 10Hz stream).
      for (var i = 0; i < 10; i++) {
        service.emitSignal(1.0 + i, isSimulator: true);
        await Future.delayed(const Duration(milliseconds: 10));
      }
      await Future.delayed(const Duration(milliseconds: 250));

      // Far fewer than 10 emissions — the sampleTime transformer throttled them.
      expect(emitted.length, lessThanOrEqualTo(2));
      expect(emitted.last, isA<BleTelemetryActiveState>());
      await sub.cancel();
    });

    test('distinct() drops an exactly-equal consecutive sample', () async {
      final emitted = <BleState>[];
      final sub = bloc.stream.listen(emitted.add);

      bloc.add(const BleStartTelemetryRequested());
      await Future.delayed(const Duration(milliseconds: 20));

      service.emitSignal(3.3, isSimulator: true);
      await Future.delayed(const Duration(milliseconds: 220));
      service.emitSignal(3.3, isSimulator: true);
      await Future.delayed(const Duration(milliseconds: 220));

      final active = emitted.whereType<BleTelemetryActiveState>().toList();
      expect(active.length, equals(1));
      expect(active.single.currentSignal, equals(3.3));
      await sub.cancel();
    });
  });
}
