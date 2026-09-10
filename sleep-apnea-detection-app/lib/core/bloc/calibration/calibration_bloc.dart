import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../ble/i_ble_sensor_driver.dart';
import '../../monitoring/drift_and_noise_floor_envelope.dart';
import 'calibration_event.dart';
import 'calibration_state.dart';

/// The two-step IDLE Band calibration loop (AD-04 idle sample + AD-05 wear
/// check) as a bloc. Pure structural extraction of
/// `_IdleBandCalibrationWizardState`: the [IdleBandAccumulator] live readout,
/// the [BreathExcursionDetector], the wear-check `Timer` and the `runId` guard
/// all move here unchanged. It consumes the injected [IBLESensorDriver]
/// (AD-12) and never constructs a driver.
class CalibrationBloc extends Bloc<CalibrationEvent, CalibrationState> {
  final IBLESensorDriver _bleDriver;

  StreamSubscription<double>? _idleReadoutSub;
  StreamSubscription<double>? _wearCheckSub;
  Timer? _wearCheckTimer;
  int _wearCheckRunId = 0;

  CalibrationBloc({required IBLESensorDriver bleDriver})
      : _bleDriver = bleDriver,
        super(const CalibrationState()) {
    on<CalibrationIdleSampleStarted>(_onIdleSampleStarted);
    on<CalibrationLiveBandUpdated>(_onLiveBandUpdated);
    on<CalibrationIdleSampleSucceeded>(_onIdleSampleSucceeded);
    on<CalibrationIdleSampleFailed>(_onIdleSampleFailed);
    on<CalibrationWearCheckStarted>(_onWearCheckStarted);
    on<CalibrationWearCheckProgressed>(_onWearCheckProgressed);
    on<CalibrationWearCheckSucceeded>(_onWearCheckSucceeded);
    on<CalibrationWearCheckFailed>(_onWearCheckFailed);
  }

  // --- Step 1: idle sample --------------------------------------------------

  void _onIdleSampleStarted(
    CalibrationIdleSampleStarted event,
    Emitter<CalibrationState> emit,
  ) {
    _idleReadoutSub?.cancel();
    _wearCheckTimer?.cancel();
    _wearCheckSub?.cancel();

    emit(state.copyWith(sampling: true, idleError: false, clearLiveBand: true));

    final acc = IdleBandAccumulator();
    _idleReadoutSub = _bleDriver.signalStream.listen(
      (v) {
        acc.add(v);
        add(CalibrationLiveBandUpdated(acc.band));
      },
      onError: (_) {},
    );

    _runIdleSample();
  }

  Future<void> _runIdleSample() async {
    try {
      final band = await _bleDriver.sampleIdleBand(window: kIdleSampleWindow);
      if (isClosed) return;
      add(CalibrationIdleSampleSucceeded(band));
    } catch (_) {
      // Catch *any* failure — a StateError (silent stream) or a real BLE fault
      // — so the spinner never hangs forever.
      if (isClosed) return;
      add(const CalibrationIdleSampleFailed());
    }
  }

  void _onLiveBandUpdated(
    CalibrationLiveBandUpdated event,
    Emitter<CalibrationState> emit,
  ) {
    if (!state.sampling) return;
    // Parity with the pre-refactor wizard's `setState(() => _liveBand = acc.band)`
    // — apply every update, including the early `null` ("no reading yet").
    emit(state.copyWith(
      liveBand: event.band,
      clearLiveBand: event.band == null,
    ));
  }

  void _onIdleSampleSucceeded(
    CalibrationIdleSampleSucceeded event,
    Emitter<CalibrationState> emit,
  ) {
    _idleReadoutSub?.cancel();
    _idleReadoutSub = null;
    emit(state.copyWith(
      band: event.band,
      sampling: false,
      step: CalibrationStep.wearCheck,
      wearCheckRunning: false,
    ));
  }

  void _onIdleSampleFailed(
    CalibrationIdleSampleFailed event,
    Emitter<CalibrationState> emit,
  ) {
    _idleReadoutSub?.cancel();
    _idleReadoutSub = null;
    emit(state.copyWith(sampling: false, idleError: true));
  }

  // --- Step 2: wear check -------------------------------------------------

  void _onWearCheckStarted(
    CalibrationWearCheckStarted event,
    Emitter<CalibrationState> emit,
  ) {
    final band = state.band;
    if (band == null) return;

    _wearCheckTimer?.cancel();
    _wearCheckSub?.cancel();
    final int runId = ++_wearCheckRunId;
    final detector = BreathExcursionDetector(band);

    emit(state.copyWith(
      wearCheckRunning: true,
      wearCheckFailed: false,
      wearCheckConnectionLost: false,
      validCycles: 0,
    ));

    _wearCheckSub = _bleDriver.signalStream.listen(
      (v) {
        if (runId != _wearCheckRunId) return;
        detector.add(v);
        add(CalibrationWearCheckProgressed(detector.validCycleCount, runId));
      },
      onError: (_) =>
          add(CalibrationWearCheckFailed(runId, connectionLost: true)),
      onDone: () =>
          add(CalibrationWearCheckFailed(runId, connectionLost: true)),
    );

    _wearCheckTimer = Timer(kWearCheckWindow, () {
      add(CalibrationWearCheckFailed(runId));
    });
  }

  void _onWearCheckProgressed(
    CalibrationWearCheckProgressed event,
    Emitter<CalibrationState> emit,
  ) {
    if (event.runId != _wearCheckRunId) return;
    if (event.validCycles != state.validCycles) {
      emit(state.copyWith(validCycles: event.validCycles));
    }
    if (event.validCycles >= kRequiredValidCycles) {
      add(CalibrationWearCheckSucceeded(event.runId));
    }
  }

  void _onWearCheckSucceeded(
    CalibrationWearCheckSucceeded event,
    Emitter<CalibrationState> emit,
  ) {
    if (event.runId != _wearCheckRunId) return;
    _wearCheckRunId++; // invalidate any further callbacks from this run
    _wearCheckTimer?.cancel();
    _wearCheckSub?.cancel();
    _wearCheckSub = null;
    emit(state.copyWith(
      wearCheckRunning: false,
      step: CalibrationStep.complete,
    ));
  }

  void _onWearCheckFailed(
    CalibrationWearCheckFailed event,
    Emitter<CalibrationState> emit,
  ) {
    if (event.runId != _wearCheckRunId) return;
    _wearCheckTimer?.cancel();
    _wearCheckSub?.cancel();
    _wearCheckSub = null;
    emit(state.copyWith(
      wearCheckRunning: false,
      wearCheckFailed: true,
      wearCheckConnectionLost: event.connectionLost,
    ));
  }

  @override
  Future<void> close() {
    _idleReadoutSub?.cancel();
    _wearCheckSub?.cancel();
    _wearCheckTimer?.cancel();
    return super.close();
  }
}
