import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../ble/ble_telemetry_service.dart';
import 'ble_event.dart';
import 'ble_state.dart';

class BleBloc extends Bloc<BleEvent, BleState> {
  final BleTelemetryService _telemetryService;
  StreamSubscription<double>? _signalSubscription;

  BleBloc({BleTelemetryService? telemetryService})
      : _telemetryService = telemetryService ?? BleTelemetryService(),
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

  void _onSignalSampleReceived(
    BleSignalSampleReceived event,
    Emitter<BleState> emit,
  ) {
    emit(BleTelemetryActiveState(
      currentSignal: event.signal,
      isSimulatorMode: _telemetryService.isSimulatorActive,
      estimatedBatteryDrainPercent: 0.5,
    ));
  }

  @override
  Future<void> close() {
    _signalSubscription?.cancel();
    return super.close();
  }
}
