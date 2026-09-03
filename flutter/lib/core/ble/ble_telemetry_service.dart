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

class BleTelemetryService implements IBLESensorDriver {
  static final BleTelemetryService _instance = BleTelemetryService._internal();
  factory BleTelemetryService() => _instance;
  BleTelemetryService._internal();

  BehaviorSubject<double> _signalSubject = BehaviorSubject<double>.seeded(5.0);
  BehaviorSubject<bool> _isSimulatorSubject = BehaviorSubject<bool>.seeded(true);
  BehaviorSubject<SimulatorScenario> _scenarioSubject =
      BehaviorSubject<SimulatorScenario>.seeded(SimulatorScenario.none);

  ValueStream<double> get signalStream => _signalSubject.stream;

  @override
  Stream<double> get thermalStream => _signalSubject.stream;

  @override
  double get apneaThreshold => 0.5;

  ValueStream<bool> get isSimulatorStream => _isSimulatorSubject.stream;
  ValueStream<SimulatorScenario> get scenarioStream => _scenarioSubject.stream;

  double get latestSignal => _signalSubject.value;
  bool get isSimulatorActive => _isSimulatorSubject.value;
  SimulatorScenario get currentScenario => _scenarioSubject.value;

  Timer? _simulationTimer;
  double _step = 0.0;

  @override
  Future<bool> scanAndConnect() async {
    _isSimulatorSubject.add(true);
    return true;
  }

  @override
  void startTelemetryLogging() {
    startSimulationScenario(SimulatorScenario.normalRespiration);
  }

  @override
  void stopTelemetryLogging() {
    stopSimulation();
  }

  @override
  void disconnect() {
    stopSimulation();
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
