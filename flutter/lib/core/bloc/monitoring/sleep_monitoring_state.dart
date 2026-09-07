import 'package:equatable/equatable.dart';
import '../../monitoring/drift_and_noise_floor_envelope.dart';
import '../../permissions/ble_permission_service.dart';

/// Screen-level status of the sleep-monitoring page, in the same precedence the
/// widget rendered its `if` ladder in before the extraction.
enum SleepMonitoringStatus {
  checkingPermission,
  permissionCheckFailed,
  permissionBlocked,
  setup,
  monitoring,
}

/// State for [SleepMonitoringBloc] — the whole `_MeasurementPageState`
/// orchestration (permission gate, BLE connect, calibration hand-off, nocturnal
/// monitoring, Tier-1 alert overlay) as one immutable value. Behaviour is
/// identical to the pre-refactor widget; only where the state lives changed.
class SleepMonitoringState extends Equatable {
  final SleepMonitoringStatus status;
  final BlePermissionStatus? permissionStatus;
  final bool isBleConnected;

  /// Bumped on every (re)connect — used by the view as the calibration
  /// wizard's `ValueKey` so a re-worn sensor re-runs the wizard.
  final int connectGeneration;

  final IdleBand? idleBand;
  final bool isCalibrationComplete;

  final bool showAlertOverlay;
  final int alertCountdown;
  final double latestSignalValue;
  final List<double> recentSignalBuffer;

  /// Mirror of `ApneaEvaluator.inBandDuration` for the dev telemetry readout.
  final double inBandDuration;

  const SleepMonitoringState({
    this.status = SleepMonitoringStatus.checkingPermission,
    this.permissionStatus,
    this.isBleConnected = false,
    this.connectGeneration = 0,
    this.idleBand,
    this.isCalibrationComplete = false,
    this.showAlertOverlay = false,
    this.alertCountdown = 30,
    this.latestSignalValue = 0.0,
    this.recentSignalBuffer = const [],
    this.inBandDuration = 0.0,
  });

  bool get canStartMonitoring => idleBand != null && isCalibrationComplete;

  SleepMonitoringState copyWith({
    SleepMonitoringStatus? status,
    BlePermissionStatus? permissionStatus,
    bool clearPermissionStatus = false,
    bool? isBleConnected,
    int? connectGeneration,
    IdleBand? idleBand,
    bool clearIdleBand = false,
    bool? isCalibrationComplete,
    bool? showAlertOverlay,
    int? alertCountdown,
    double? latestSignalValue,
    List<double>? recentSignalBuffer,
    double? inBandDuration,
  }) {
    return SleepMonitoringState(
      status: status ?? this.status,
      permissionStatus:
          clearPermissionStatus ? null : (permissionStatus ?? this.permissionStatus),
      isBleConnected: isBleConnected ?? this.isBleConnected,
      connectGeneration: connectGeneration ?? this.connectGeneration,
      idleBand: clearIdleBand ? null : (idleBand ?? this.idleBand),
      isCalibrationComplete: isCalibrationComplete ?? this.isCalibrationComplete,
      showAlertOverlay: showAlertOverlay ?? this.showAlertOverlay,
      alertCountdown: alertCountdown ?? this.alertCountdown,
      latestSignalValue: latestSignalValue ?? this.latestSignalValue,
      recentSignalBuffer: recentSignalBuffer ?? this.recentSignalBuffer,
      inBandDuration: inBandDuration ?? this.inBandDuration,
    );
  }

  @override
  List<Object?> get props => [
        status,
        permissionStatus?.result,
        permissionStatus?.missingPermissionNames,
        isBleConnected,
        connectGeneration,
        idleBand,
        isCalibrationComplete,
        showAlertOverlay,
        alertCountdown,
        latestSignalValue,
        // O(1) per-tick equality: the waveform still rebuilds each tick via the
        // length change plus `latestSignalValue`, without an O(n) list walk.
        recentSignalBuffer.length,
        inBandDuration,
      ];
}
