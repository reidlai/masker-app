import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../ble/i_ble_sensor_driver.dart';
import '../../ble/ble_receiver_service.dart';
import '../../ble/ble_simulator_driver.dart';
import 'ble_event.dart';
import 'ble_state.dart';

/// Telemetry-readout BLoC. Per AD-11/AD-12 it depends only on the abstract
/// [IBLESensorDriver] — supplied by Constructor DI from the single boot-time
/// [BleReceiverService] unified queue — never on a concrete driver.
class BleBloc extends Bloc<BleEvent, BleState> {
  final IBLESensorDriver _telemetryService;
  StreamSubscription<double>? _signalSubscription;

  BleBloc({required IBLESensorDriver telemetryService})
      : _telemetryService = telemetryService,
        super(const BleInitialState()) {
    on<BleSignalSampleReceived>(
      _onSignalSampleReceived,
      transformer: (events, mapper) => events
          // Battery optimization: Throttles high-frequency 10Hz BLE stream to 5 FPS (200ms) for UI rendering
          .sampleTime(const Duration(milliseconds: 200))
          .distinct()
          .switchMap(mapper),
    );

    on<BleStartTelemetryRequested>((event, emit) {
      _signalSubscription?.cancel();
      _signalSubscription = _telemetryService.signalStream.listen((signal) {
        add(BleSignalSampleReceived(signal));
      });
    });

    on<BleStopTelemetryRequested>((event, emit) {
      _signalSubscription?.cancel();
      emit(const BleDisconnectedState());
    });
  }

  bool get _isSimulatorMode {
    final d = _telemetryService;
    if (d is BleReceiverService) return d.isSimulatorActive;
    if (d is BleSimulatorDriver) return d.isSimulatorActive;
    return false;
  }

  void _onSignalSampleReceived(
    BleSignalSampleReceived event,
    Emitter<BleState> emit,
  ) {
    emit(BleTelemetryActiveState(
      currentSignal: event.signal,
      isSimulatorMode: _isSimulatorMode,
      estimatedBatteryDrainPercent: 0.5,
    ));
  }

  @override
  Future<void> close() {
    _signalSubscription?.cancel();
    return super.close();
  }
}
