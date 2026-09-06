import '../monitoring/idle_band.dart';

/// Explicit lifecycle stages of the sleep-apnea monitoring cycle.
///
/// `wearCheck` is intentionally absent: the wizard's wear check runs by
/// observing [IBLESensorDriver.signalStream] between the idle sample and
/// monitoring start — no driver emits a distinct wear-check phase.
enum SensorMonitoringPhase {
  disconnected,
  idle,
  calibratingIdleBand,
  monitoring,
}

abstract class IBLESensorDriver {
  /// Unified 10 Hz raw bio-signal stream (AD-12).
  ///
  /// Continuously live from a successful [scanAndConnect] until [disconnect].
  /// [sampleIdleBand] and [startMonitoringSession] *re-shape* this emission —
  /// they never start it from silence. Raw signal units end to end; no L/s
  /// conversion.
  Stream<double> get signalStream;

  /// Current monitoring phase in the sleep-apnea lifecycle.
  SensorMonitoringPhase get currentPhase;

  /// Stream of phase-transition updates.
  Stream<SensorMonitoringPhase> get phaseStream;

  /// Connect to the D-BAND BLE hardware (or simulator). On success the driver
  /// starts emitting on [signalStream] and keeps emitting until [disconnect].
  Future<bool> scanAndConnect();

  /// Learn the session IDLE Band (AD-04).
  ///
  /// Observes the already-live [signalStream] for [window] and returns the
  /// running `min`/`max` of the raw samples seen — `IdleBand(lower, upper)`.
  /// The band only widens within the window; no margin is applied. Throws a
  /// [StateError] if not a single sample arrives before the window elapses.
  ///
  /// A synthetic / mock driver leaves the emitter in a band-spanning
  /// "breathing" shape on return so the wizard's wear check observes strict
  /// excursions on both sides of the returned band; a driver fed by a real
  /// characteristic does no shaping — the patient's own breath supplies the
  /// excursions.
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow});

  /// Start the nocturnal monitoring session (re-shapes the live emission).
  void startMonitoringSession();

  /// Stop the monitoring session. Per AD-12 the emitter stays live (re-shaped
  /// to a resting signal) until [disconnect].
  void stopMonitoringSession();

  /// Terminate the connection and release BLE resources. Closes [signalStream].
  void disconnect();
}
