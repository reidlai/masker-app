import 'dart:async';
import 'dart:math';
import 'package:rxdart/rxdart.dart';
import 'i_ble_sensor_driver.dart';

enum SimulatorScenario {
  none,
  idleNoise,
  activeBreath,
  normalRespiration,
  apneaAlert,
  recovery,
}

/// Developer & QA Telemetry Simulator implementing [IBLESensorDriver].
/// Generates synthetic 10Hz bio-signal streams and customizable test scenarios.
class BleSimulatorDriver implements IBLESensorDriver {
  static final BleSimulatorDriver _instance = BleSimulatorDriver._internal();
  factory BleSimulatorDriver() => _instance;
  BleSimulatorDriver._internal();

  BehaviorSubject<double> _signalSubject = BehaviorSubject<double>.seeded(5.0);
  BehaviorSubject<bool> _isSimulatorSubject = BehaviorSubject<bool>.seeded(true);
  BehaviorSubject<SimulatorScenario> _scenarioSubject =
      BehaviorSubject<SimulatorScenario>.seeded(SimulatorScenario.none);

  ValueStream<double> get signalStream => _signalSubject.stream;

  @override
  double get signalThreshold => 0.5;

  ValueStream<bool> get isSimulatorStream => _isSimulatorSubject.stream;
  ValueStream<SimulatorScenario> get scenarioStream => _scenarioSubject.stream;

  double get latestSignal => _signalSubject.value;
  bool get isSimulatorActive => _isSimulatorSubject.value;
  SimulatorScenario get currentScenario => _scenarioSubject.value;

  Timer? _simulationTimer;
  double _step = 0.0;

  BehaviorSubject<SensorMonitoringPhase> _phaseSubject =
      BehaviorSubject<SensorMonitoringPhase>.seeded(SensorMonitoringPhase.disconnected);

  @override
  SensorMonitoringPhase get currentPhase => _phaseSubject.value;

  @override
  Stream<SensorMonitoringPhase> get phaseStream => _phaseSubject.stream;

  @override
  Future<bool> scanAndConnect() async {
    _isSimulatorSubject.add(true);
    _phaseSubject.add(SensorMonitoringPhase.idle);
    return true;
  }

  // --- Stage 1: Idle Room Noise Calibration Lifecycle ---
  @override
  Future<void> startIdleCalibration() async {
    _phaseSubject.add(SensorMonitoringPhase.calibratingIdle);
    startSimulationScenario(SimulatorScenario.idleNoise);
  }

  @override
  Future<double> stopIdleCalibration() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _phaseSubject.add(SensorMonitoringPhase.idle);
    return 0.4;
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

  // --- Stage 2: Training Calibration Lifecycle ---
  @override
  Future<void> startTrainingCalibration() async {
    _phaseSubject.add(SensorMonitoringPhase.calibratingTraining);
    startSimulationScenario(SimulatorScenario.activeBreath);
  }

  @override
  Future<double> stopTrainingCalibration() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _phaseSubject.add(SensorMonitoringPhase.idle);
    return 0.5;
  }

  // --- Stage 3: Nocturnal Sleeping Monitoring Lifecycle ---
  @override
  void startMonitoringSession() {
    _phaseSubject.add(SensorMonitoringPhase.monitoring);
    startSimulationScenario(SimulatorScenario.normalRespiration);
  }

  @override
  void stopMonitoringSession() {
    stopSimulation();
    _phaseSubject.add(SensorMonitoringPhase.idle);
  }

  @override
  void disconnect() {
    stopSimulation();
    _phaseSubject.add(SensorMonitoringPhase.disconnected);
  }

  void emitSignal(double value, {bool isSimulator = false}) {
    if (_signalSubject.isClosed) {
      _signalSubject = BehaviorSubject<double>.seeded(value);
    }
    if (_isSimulatorSubject.isClosed) {
      _isSimulatorSubject = BehaviorSubject<bool>.seeded(isSimulator);
    }
    _isSimulatorSubject.add(isSimulator);
    _signalSubject.add(value);
  }

  void setSimulatorEnabled(bool enabled) {
    if (_isSimulatorSubject.isClosed) {
      _isSimulatorSubject = BehaviorSubject<bool>.seeded(enabled);
    }
    _isSimulatorSubject.add(enabled);
    if (!enabled) {
      stopSimulation();
    }
  }

  void startSimulationScenario(SimulatorScenario scenario) {
    if (_isSimulatorSubject.isClosed) {
      _isSimulatorSubject = BehaviorSubject<bool>.seeded(true);
    }
    if (_scenarioSubject.isClosed) {
      _scenarioSubject = BehaviorSubject<SimulatorScenario>.seeded(scenario);
    }
    _isSimulatorSubject.add(true);
    _scenarioSubject.add(scenario);
    _simulationTimer?.cancel();
    _step = 0.0;

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _step += 0.1;
      double signal = 5.0;

      switch (scenario) {
        case SimulatorScenario.idleNoise:
          signal = 0.3 + (0.1 * sin(_step * 3));
          break;
        case SimulatorScenario.activeBreath:
          signal = 2.5 * (1 + sin(_step * 2)) + 0.4;
          break;
        case SimulatorScenario.normalRespiration:
          signal = 2.5 * (1 + sin(_step * 1.6)) + 0.4;
          break;
        case SimulatorScenario.apneaAlert:
          signal = 0.05;
          break;
        case SimulatorScenario.recovery:
          signal = 3.0 * (1 + sin(_step * 2)) + 1.0;
          break;
        case SimulatorScenario.none:
          signal = 5.0;
          break;
      }

      if (!_signalSubject.isClosed) {
        _signalSubject.add(signal);
      }
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    if (!_scenarioSubject.isClosed) {
      _scenarioSubject.add(SimulatorScenario.none);
    }
  }

  void resetForTest() {
    stopSimulation();
    if (_signalSubject.isClosed) {
      _signalSubject = BehaviorSubject<double>.seeded(5.0);
    } else {
      _signalSubject.add(5.0);
    }
    if (_isSimulatorSubject.isClosed) {
      _isSimulatorSubject = BehaviorSubject<bool>.seeded(true);
    } else {
      _isSimulatorSubject.add(true);
    }
    if (_scenarioSubject.isClosed) {
      _scenarioSubject = BehaviorSubject<SimulatorScenario>.seeded(SimulatorScenario.none);
    } else {
      _scenarioSubject.add(SimulatorScenario.none);
    }
  }

  void dispose() {
    stopSimulation();
  }
}
