import 'package:equatable/equatable.dart';
import '../../monitoring/apnea_evaluator.dart';
import '../../monitoring/drift_and_noise_floor_envelope.dart';

/// Events for [SleepMonitoringBloc]. Public events map 1:1 to the user actions
/// and lifecycle callbacks the widget used to handle inline; the stream-fed
/// events are pumped only from the bloc's own `StreamSubscription`s (evaluator
/// state / countdown, the unified signal queue, the simulator scenario stream).
abstract class SleepMonitoringEvent extends Equatable {
  const SleepMonitoringEvent();

  @override
  List<Object?> get props => const [];
}

/// Boot the page: run the live permission check and, when granted, connect.
class SleepMonitoringStarted extends SleepMonitoringEvent {
  const SleepMonitoringStarted();
}

/// App returned to the foreground — re-check permission live (e.g. after the
/// user granted it in system Settings) without an app restart.
class SleepMonitoringAppResumed extends SleepMonitoringEvent {
  const SleepMonitoringAppResumed();
}

/// "Retry" on the permission-check-failed screen.
class SleepMonitoringPermissionRetried extends SleepMonitoringEvent {
  const SleepMonitoringPermissionRetried();
}

/// The calibration wizard produced a valid session [IdleBand].
class SleepMonitoringCalibrationCompleted extends SleepMonitoringEvent {
  final IdleBand band;
  const SleepMonitoringCalibrationCompleted(this.band);

  @override
  List<Object?> get props => [band];
}

/// "Start Nocturnal Sleep Monitoring".
class SleepMonitoringSessionStarted extends SleepMonitoringEvent {
  const SleepMonitoringSessionStarted();
}

/// Long-press anywhere on the night-mode screen — end the session.
class SleepMonitoringSessionStopped extends SleepMonitoringEvent {
  const SleepMonitoringSessionStopped();
}

/// "I'm Safe" tap on the Tier-1 alert overlay.
class SleepMonitoringPatientSafeAcknowledged extends SleepMonitoringEvent {
  const SleepMonitoringPatientSafeAcknowledged();
}

// --- internal (stream-fed) ------------------------------------------------------

class SleepMonitoringSignalReceived extends SleepMonitoringEvent {
  final double signal;
  const SleepMonitoringSignalReceived(this.signal);

  @override
  List<Object?> get props => [signal];
}

class SleepMonitoringEvaluatorStateChanged extends SleepMonitoringEvent {
  final ApneaState state;
  const SleepMonitoringEvaluatorStateChanged(this.state);

  @override
  List<Object?> get props => [state];
}

class SleepMonitoringCountdownChanged extends SleepMonitoringEvent {
  final int seconds;
  const SleepMonitoringCountdownChanged(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

class SleepMonitoringScenarioChanged extends SleepMonitoringEvent {
  const SleepMonitoringScenarioChanged();
}
