import 'dart:async';
import 'dart:math';
import 'i_ble_sensor_driver.dart';

enum BLEDeviceState { disconnected, scanning, connecting, connected }

class BLESensorDriver implements IBLESensorDriver {
  static const String serviceUuid = "0x180D";
  static const String characteristicUuid = "0x2A37";

  BLEDeviceState _state = BLEDeviceState.disconnected;
  BLEDeviceState get state => _state;

  SensorMonitoringPhase _currentPhase = SensorMonitoringPhase.disconnected;
  @override
  SensorMonitoringPhase get currentPhase => _currentPhase;

  StreamController<SensorMonitoringPhase>? _phaseStreamController;
  @override
  Stream<SensorMonitoringPhase> get phaseStream {
    _phaseStreamController ??= StreamController<SensorMonitoringPhase>.broadcast();
    return _phaseStreamController!.stream;
  }

  void _updatePhase(SensorMonitoringPhase newPhase) {
    _currentPhase = newPhase;
    _phaseStreamController?.add(newPhase);
  }

  StreamController<double>? _signalStreamController;
  @override
  Stream<double> get signalStream {
    _signalStreamController ??= StreamController<double>.broadcast();
    return _signalStreamController!.stream;
  }

  Timer? _telemetryTimer;
  double _ambientNoiseFloor = 0.5; // N_idle
  double _breathBaselineVpp = 5.0; // V_pp
  double _signalThreshold = 0.5;    // 0.10 * V_pp

  double get ambientNoiseFloor => _ambientNoiseFloor;
  double get breathBaselineVpp => _breathBaselineVpp;

  @override
  double get signalThreshold => _signalThreshold;

  @override
  Future<bool> scanAndConnect() async {
    _state = BLEDeviceState.scanning;
    await Future.delayed(const Duration(milliseconds: 600));
    _state = BLEDeviceState.connecting;
    await Future.delayed(const Duration(milliseconds: 600));
    _state = BLEDeviceState.connected;
    _updatePhase(SensorMonitoringPhase.idle);
    return true;
  }

  // --- Stage 1 Calibration Lifecycle ---
  @override
  Future<void> startIdleCalibration() async {
    _updatePhase(SensorMonitoringPhase.calibratingIdle);
  }

  @override
  Future<double> stopIdleCalibration() async {
    double noiseSum = 0.0;
    final Random rnd = Random();
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      noiseSum += 0.3 + (rnd.nextDouble() * 0.2); // ~0.4°C noise
    }
    _ambientNoiseFloor = noiseSum / 10.0;
    _updatePhase(SensorMonitoringPhase.idle);
    return _ambientNoiseFloor;
  }

  @override
  Future<double> calibrateStage1NoiseFloor() async {
    await startIdleCalibration();
    return await stopIdleCalibration();
  }

  @override
  Future<double> calibrateStage1NoiseCeiling() async {
    return await calibrateStage1NoiseFloor();
  }

  // --- Stage 2 Calibration Lifecycle ---
  @override
  Future<void> startTrainingCalibration() async {
    _updatePhase(SensorMonitoringPhase.calibratingTraining);
  }

  @override
  Future<double> stopTrainingCalibration() async {
    double maxBreath = 0.0;
    final Random rnd = Random();
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      double sample = 4.5 + (rnd.nextDouble() * 1.5); // ~5.0°C active breath
      if (sample > maxBreath) maxBreath = sample;
    }
    _breathBaselineVpp = maxBreath;
    _signalThreshold = 0.10 * _breathBaselineVpp;
    _updatePhase(SensorMonitoringPhase.idle);
    return _signalThreshold;
  }

  // --- Stage 3 Monitoring Lifecycle ---
  @override
  void startMonitoringSession() {
    _telemetryTimer?.cancel();
    _updatePhase(SensorMonitoringPhase.monitoring);
    double step = 0.0;
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      step += 0.1;
      // 10Hz sine wave simulating thermal breath stream
      double signal = (_breathBaselineVpp / 2) * (1 + sin(step)) + _ambientNoiseFloor;
      _signalStreamController?.add(signal);
    });
  }

  @override
  void stopMonitoringSession() {
    _telemetryTimer?.cancel();
    _updatePhase(SensorMonitoringPhase.idle);
  }

  @override
  void disconnect() {
    stopMonitoringSession();
    _signalStreamController?.close();
    _signalStreamController = null;
    _state = BLEDeviceState.disconnected;
    _updatePhase(SensorMonitoringPhase.disconnected);
    _phaseStreamController?.close();
    _phaseStreamController = null;
  }
}
