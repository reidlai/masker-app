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
  });
}
