import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../ble/i_ble_sensor_driver.dart';
import '../../monitoring/apnea_evaluator.dart';
import '../../permissions/ble_permission_service.dart';
import 'sleep_monitoring_event.dart';
import 'sleep_monitoring_state.dart';

/// Orchestrates the whole sleep-monitoring page (`MOB_MEASUREMENT`): the live
/// Bluetooth-permission gate, the BLE connect, the calibration hand-off, the
/// nocturnal [ApneaEvaluator] lifecycle and the Tier-1 alert overlay.
///
/// Pure structural extraction of `_MeasurementPageState` — every branch,
/// timing and copy is identical to the pre-refactor widget. It consumes the
/// single unified bio-signal queue (AD-12) through the injected
/// [IBLESensorDriver]; it never constructs a driver or opens a second stream.
class SleepMonitoringBloc
    extends Bloc<SleepMonitoringEvent, SleepMonitoringState> {
  final IBLESensorDriver _driver;
  final BlePermissionService _permissionService;
  final bool _isDevMode;

  /// Fires whenever the developer/QA simulator scenario changes — used to reset
  /// the evaluator mid-session so a stale alarm does not carry across.
  final Stream<void>? _scenarioResetStream;

  ApneaEvaluator? _apneaEvaluator;
  StreamSubscription<double>? _signalSub;
  StreamSubscription<ApneaState>? _evaluatorStateSub;
  StreamSubscription<int>? _countdownSub;
  StreamSubscription<void>? _scenarioSub;

  static const _devGrantedStub =
      BlePermissionStatus(BlePermissionResult.granted, []);

  SleepMonitoringBloc({
    required IBLESensorDriver driver,
    BlePermissionService permissionService = const BlePermissionService(),
    bool isDevMode = false,
    Stream<void>? scenarioResetStream,
  })  : _driver = driver,
        _permissionService = permissionService,
        _isDevMode = isDevMode,
        _scenarioResetStream = scenarioResetStream,
        super(const SleepMonitoringState()) {
    on<SleepMonitoringStarted>(_onStarted);
    on<SleepMonitoringAppResumed>(_onAppResumed);
    on<SleepMonitoringPermissionRetried>(_onPermissionRetried);
    on<SleepMonitoringCalibrationCompleted>(_onCalibrationCompleted);
    on<SleepMonitoringSessionStarted>(_onSessionStarted);
    on<SleepMonitoringSessionStopped>(_onSessionStopped);
    on<SleepMonitoringPatientSafeAcknowledged>(_onPatientSafeAcknowledged);
    on<SleepMonitoringSignalReceived>(_onSignalReceived);
    on<SleepMonitoringEvaluatorStateChanged>(_onEvaluatorStateChanged);
    on<SleepMonitoringCountdownChanged>(_onCountdownChanged);
    on<SleepMonitoringScenarioChanged>(_onScenarioChanged);
  }

  // --- permission gate + connect ------------------------------------------------

  Future<void> _onStarted(
    SleepMonitoringStarted event,
    Emitter<SleepMonitoringState> emit,
  ) =>
      _runStartFlow(emit);

  Future<void> _onPermissionRetried(
    SleepMonitoringPermissionRetried event,
    Emitter<SleepMonitoringState> emit,
  ) async {
    emit(state.copyWith(
      status: SleepMonitoringStatus.checkingPermission,
    ));
    await _runStartFlow(emit);
  }

  Future<void> _runStartFlow(Emitter<SleepMonitoringState> emit) async {
    // The simulator never touches real Bluetooth hardware or OS permissions,
    // so DEV_MODE bypasses the live permission gate entirely.
    if (_isDevMode) {
      emit(state.copyWith(
        status: SleepMonitoringStatus.setup,
        permissionStatus: _devGrantedStub,
      ));
      await _connect(emit);
      return;
    }

    try {
      final status = await _permissionService.checkPermission();
      if (isClosed) return;
      emit(state.copyWith(
        permissionStatus: status,
        status: status.isGranted
            ? SleepMonitoringStatus.setup
            : SleepMonitoringStatus.permissionBlocked,
      ));
      if (status.isGranted) {
        await _connect(emit);
      }
    } catch (_) {
      // Never hang on the spinner forever if the platform channel throws —
      // surface a retry instead.
      if (isClosed) return;
      emit(state.copyWith(
        status: SleepMonitoringStatus.permissionCheckFailed,
      ));
    }
  }

  Future<void> _onAppResumed(
    SleepMonitoringAppResumed event,
    Emitter<SleepMonitoringState> emit,
  ) async {
    if (_isDevMode) {
      if (!state.isBleConnected) {
        await _connect(emit);
      }
      return;
    }

    final wasBlocked = state.permissionStatus != null &&
        !state.permissionStatus!.isGranted;
    try {
      final status = await _permissionService.checkPermission();
      if (isClosed) return;
      emit(state.copyWith(
        permissionStatus: status,
        status: state.status == SleepMonitoringStatus.monitoring
            ? SleepMonitoringStatus.monitoring
            : (status.isGranted
                ? SleepMonitoringStatus.setup
                : SleepMonitoringStatus.permissionBlocked),
      ));
      if (wasBlocked && status.isGranted && !state.isBleConnected) {
        await _connect(emit);
      }
    } catch (_) {
      // Leave existing state as-is on a transient resume-check failure.
    }
  }

  Future<void> _connect(Emitter<SleepMonitoringState> emit) async {
    // A fresh connection invalidates any prior calibration — the band is
    // per-session and a re-worn sensor must re-run the wizard.
    emit(state.copyWith(
      clearIdleBand: true,
      isCalibrationComplete: false,
      connectGeneration: state.connectGeneration + 1,
    ));
    final success = await _driver.scanAndConnect();
    if (isClosed) return;
    emit(state.copyWith(isBleConnected: success));
  }

  // --- calibration hand-off ---------------------------------------------------

  void _onCalibrationCompleted(
    SleepMonitoringCalibrationCompleted event,
    Emitter<SleepMonitoringState> emit,
  ) {
    emit(state.copyWith(idleBand: event.band, isCalibrationComplete: true));
  }

  // --- nocturnal monitoring -------------------------------------------------

  void _onSessionStarted(
    SleepMonitoringSessionStarted event,
    Emitter<SleepMonitoringState> emit,
  ) {
    if (state.idleBand == null) return;

    _apneaEvaluator = ApneaEvaluator(idleBand: state.idleBand!);

    _evaluatorStateSub = _apneaEvaluator!.stateStream.listen((s) {
      if (isClosed) return;
      add(SleepMonitoringEvaluatorStateChanged(s));
    });
    _countdownSub = _apneaEvaluator!.countdownStream.listen((n) {
      if (isClosed) return;
      add(SleepMonitoringCountdownChanged(n));
    });

    _scenarioSub = _scenarioResetStream?.listen((_) {
      if (isClosed) return;
      add(const SleepMonitoringScenarioChanged());
    });

    // The one unified signalStream (AD-12) is the only source feeding the
    // evaluator — never a second live source.
    _signalSub = _driver.signalStream.listen((signal) {
      if (isClosed) return;
      _apneaEvaluator?.evaluateSignal(signal);
      add(SleepMonitoringSignalReceived(signal));
    });

    emit(state.copyWith(
      status: SleepMonitoringStatus.monitoring,
      showAlertOverlay: false,
      alertCountdown: 30,
      latestSignalValue: 0.0,
      recentSignalBuffer: const [],
      inBandDuration: 0.0,
    ));

    _driver.startMonitoringSession();
  }

  void _onSessionStopped(
    SleepMonitoringSessionStopped event,
    Emitter<SleepMonitoringState> emit,
  ) {
    _cancelMonitoringSubs();
    _apneaEvaluator?.dispose();
    _apneaEvaluator = null;
    _driver.stopMonitoringSession();

    emit(state.copyWith(
      status: SleepMonitoringStatus.setup,
      showAlertOverlay: false,
      inBandDuration: 0.0,
    ));
  }

  void _onPatientSafeAcknowledged(
    SleepMonitoringPatientSafeAcknowledged event,
    Emitter<SleepMonitoringState> emit,
  ) {
    _apneaEvaluator?.acknowledgePatientSafe();
    emit(state.copyWith(showAlertOverlay: false));
  }

  void _onEvaluatorStateChanged(
    SleepMonitoringEvaluatorStateChanged event,
    Emitter<SleepMonitoringState> emit,
  ) {
    if (event.state == ApneaState.breachAlert) {
      emit(state.copyWith(showAlertOverlay: true));
    } else if (event.state == ApneaState.patientSafe) {
      emit(state.copyWith(showAlertOverlay: false));
    }
  }

  void _onCountdownChanged(
    SleepMonitoringCountdownChanged event,
    Emitter<SleepMonitoringState> emit,
  ) {
    emit(state.copyWith(alertCountdown: event.seconds));
  }

  void _onSignalReceived(
    SleepMonitoringSignalReceived event,
    Emitter<SleepMonitoringState> emit,
  ) {
    final buffer = List<double>.of(state.recentSignalBuffer)..add(event.signal);
    if (buffer.length > 20) buffer.removeAt(0);
    emit(state.copyWith(
      latestSignalValue: event.signal,
      recentSignalBuffer: buffer,
      inBandDuration: _apneaEvaluator?.inBandDuration ?? 0.0,
    ));
  }

  void _onScenarioChanged(
    SleepMonitoringScenarioChanged event,
    Emitter<SleepMonitoringState> emit,
  ) {
    _apneaEvaluator?.reset();
    emit(state.copyWith(showAlertOverlay: false));
  }

  void _cancelMonitoringSubs() {
    _scenarioSub?.cancel();
    _scenarioSub = null;
    _signalSub?.cancel();
    _signalSub = null;
    _evaluatorStateSub?.cancel();
    _evaluatorStateSub = null;
    _countdownSub?.cancel();
    _countdownSub = null;
  }

  @override
  Future<void> close() {
    _cancelMonitoringSubs();
    _apneaEvaluator?.dispose();
    // AD-12: `_driver` is the app-lifetime BleReceiverService — the receiver
    // service and its queue survive for the next session, so tearing down this
    // page-scoped bloc must not disconnect the shared driver.
    return super.close();
  }
}
