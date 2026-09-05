/// Represents the explicit lifecycle stages of the Sleep Apnea Breathing Monitoring Cycle.
enum SensorMonitoringPhase {
  disconnected,
  idle,
  calibratingIdle,
  calibratingTraining,
  monitoring,
}

abstract class IBLESensorDriver {
  /// 10Hz Bio-Signal Stream (L/s)
  Stream<double> get signalStream;

  /// Computed Signal Detection Threshold (10% of V_pp)
  double get signalThreshold;

  /// Current monitoring phase in the sleep apnea lifecycle
  SensorMonitoringPhase get currentPhase;

  /// Stream of phase transition updates
  Stream<SensorMonitoringPhase> get phaseStream;

  /// Connect to D-BAND BLE Hardware / Simulator
  Future<bool> scanAndConnect();

  // --- Stage 1: Idle Room Noise Calibration Lifecycle ---
  /// Start sampling room temperature noise floor (N_idle)
  Future<void> startIdleCalibration();

  /// Stop idle calibration and return computed ambient noise floor (N_idle)
  Future<double> stopIdleCalibration();

  /// Legacy helper executing full Stage 1 noise floor sampling cycle
  Future<double> calibrateStage1NoiseFloor();

  /// Legacy helper executing full Stage 1 noise ceiling sampling cycle
  Future<double> calibrateStage1NoiseCeiling();

  // --- Stage 2: Training Calibration Lifecycle ---
  /// Start sampling training thermal delta (V_pp)
  Future<void> startTrainingCalibration();

  /// Stop training calibration and return computed signal threshold (10% of V_pp)
  Future<double> stopTrainingCalibration();

  // --- Stage 3: Nocturnal Sleeping Monitoring Lifecycle ---
  /// Start nocturnal 8+ hour sleep apnea breathing monitoring session
  void startMonitoringSession();

  /// Stop nocturnal sleep apnea monitoring session
  void stopMonitoringSession();

  /// Terminate connection and release BLE resources
  void disconnect();
}
