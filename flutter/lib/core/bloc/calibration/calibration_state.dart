import 'package:equatable/equatable.dart';
import '../../monitoring/drift_and_noise_floor_envelope.dart';

/// Steps of the two-step IDLE Band calibration wizard (AD-04 / AD-05).
enum CalibrationStep { idleSample, wearCheck, complete }

/// State for [CalibrationBloc] — a pure structural extraction of
/// `_IdleBandCalibrationWizardState`. Every field, transition and guard is
/// identical to the pre-refactor widget.
class CalibrationState extends Equatable {
  final CalibrationStep step;

  // Step 1 — idle sample.
  final bool sampling;
  final bool idleError;
  final IdleBand? liveBand;
  final IdleBand? band;

  // Step 2 — wear check.
  final bool wearCheckRunning;
  final bool wearCheckFailed;
  final bool wearCheckConnectionLost;
  final int validCycles;

  const CalibrationState({
    this.step = CalibrationStep.idleSample,
    this.sampling = false,
    this.idleError = false,
    this.liveBand,
    this.band,
    this.wearCheckRunning = false,
    this.wearCheckFailed = false,
    this.wearCheckConnectionLost = false,
    this.validCycles = 0,
  });

  CalibrationState copyWith({
    CalibrationStep? step,
    bool? sampling,
    bool? idleError,
    IdleBand? liveBand,
    bool clearLiveBand = false,
    IdleBand? band,
    bool? wearCheckRunning,
    bool? wearCheckFailed,
    bool? wearCheckConnectionLost,
    int? validCycles,
  }) {
    return CalibrationState(
      step: step ?? this.step,
      sampling: sampling ?? this.sampling,
      idleError: idleError ?? this.idleError,
      liveBand: clearLiveBand ? null : (liveBand ?? this.liveBand),
      band: band ?? this.band,
      wearCheckRunning: wearCheckRunning ?? this.wearCheckRunning,
      wearCheckFailed: wearCheckFailed ?? this.wearCheckFailed,
      wearCheckConnectionLost:
          wearCheckConnectionLost ?? this.wearCheckConnectionLost,
      validCycles: validCycles ?? this.validCycles,
    );
  }

  @override
  List<Object?> get props => [
        step,
        sampling,
        idleError,
        liveBand,
        band,
        wearCheckRunning,
        wearCheckFailed,
        wearCheckConnectionLost,
        validCycles,
      ];
}
