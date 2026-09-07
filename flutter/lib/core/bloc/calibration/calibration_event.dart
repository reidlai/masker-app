import 'package:equatable/equatable.dart';
import '../../monitoring/drift_and_noise_floor_envelope.dart';

/// Events for [CalibrationBloc]. Public events map 1:1 to the wizard's two
/// buttons (and their Retry variants); the stream-fed events are pumped only
/// from the bloc's own `StreamSubscription`s / wear-check `Timer`.
abstract class CalibrationEvent extends Equatable {
  const CalibrationEvent();

  @override
  List<Object?> get props => const [];
}

/// "Start Noise Floor Sampling" — also the idle-sample "Retry".
class CalibrationIdleSampleStarted extends CalibrationEvent {
  const CalibrationIdleSampleStarted();
}

/// "I'm Ready — Start Breathing Check" — also "Retry Breathing Check".
class CalibrationWearCheckStarted extends CalibrationEvent {
  const CalibrationWearCheckStarted();
}

// --- internal (stream-fed) ------------------------------------------------------

class CalibrationLiveBandUpdated extends CalibrationEvent {
  final IdleBand? band;
  const CalibrationLiveBandUpdated(this.band);

  @override
  List<Object?> get props => [band];
}

class CalibrationIdleSampleSucceeded extends CalibrationEvent {
  final IdleBand band;
  const CalibrationIdleSampleSucceeded(this.band);

  @override
  List<Object?> get props => [band];
}

class CalibrationIdleSampleFailed extends CalibrationEvent {
  const CalibrationIdleSampleFailed();
}

class CalibrationWearCheckProgressed extends CalibrationEvent {
  final int validCycles;
  final int runId;
  const CalibrationWearCheckProgressed(this.validCycles, this.runId);

  @override
  List<Object?> get props => [validCycles, runId];
}

class CalibrationWearCheckSucceeded extends CalibrationEvent {
  final int runId;
  const CalibrationWearCheckSucceeded(this.runId);

  @override
  List<Object?> get props => [runId];
}

class CalibrationWearCheckFailed extends CalibrationEvent {
  final int runId;
  final bool connectionLost;
  const CalibrationWearCheckFailed(this.runId, {this.connectionLost = false});

  @override
  List<Object?> get props => [runId, connectionLost];
}
