import 'dart:async';
import 'dart:math';
import 'package:rxdart/rxdart.dart';
import '../monitoring/idle_band.dart';
import 'i_ble_sensor_driver.dart';

/// Developer / QA telemetry scenarios. Signal shapes are internally
/// consistent with a band learned from [idleBandSample] (~0.25–0.35):
/// [normalRespiration] and [recovery] strictly overshoot that band on both
/// sides; [inBandNoExcursion] never leaves it.
enum SimulatorScenario {
  none,
  idleBandSample,
  normalRespiration,
  inBandNoExcursion,
  recovery,
}

/// Developer & QA Telemetry Simulator implementing [IBLESensorDriver].
/// Generates a synthetic continuous 10 Hz bio-signal stream (AD-12).
class BleSimulatorDriver implements IBLESensorDriver {
  static final BleSimulatorDriver _instance = BleSimulatorDriver._internal();
  factory BleSimulatorDriver() => _instance;
  BleSimulatorDriver._internal();

  BehaviorSubject<double> _signalSubject = BehaviorSubject<double>.seeded(0.3);
  BehaviorSubject<bool> _isSimulatorSubject = BehaviorSubject<bool>.seeded(true);
  BehaviorSubject<SimulatorScenario> _scenarioSubject =
      BehaviorSubject<SimulatorScenario>.seeded(SimulatorScenario.none);

  @override
  ValueStream<double> get signalStream => _signalSubject.stream;

  ValueStream<bool> get isSimulatorStream => _isSimulatorSubject.stream;
  ValueStream<SimulatorScenario> get scenarioStream => _scenarioSubject.stream;

  double get latestSignal => _signalSubject.value;
  bool get isSimulatorActive => _isSimulatorSubject.value;
  SimulatorScenario get currentScenario => _scenarioSubject.value;

  Timer? _simulationTimer;
  double _step = 0.0;

  final BehaviorSubject<SensorMonitoringPhase> _phaseSubject =
      BehaviorSubject<SensorMonitoringPhase>.seeded(
          SensorMonitoringPhase.disconnected);

  @override
  SensorMonitoringPhase get currentPhase => _phaseSubject.value;

  @override
  Stream<SensorMonitoringPhase> get phaseStream => _phaseSubject.stream;

  @override
  Future<bool> scanAndConnect() async {
    _isSimulatorSubject.add(true);
    _phaseSubject.add(SensorMonitoringPhase.idle);
    // AD-12: start the continuous emitter now; it runs until disconnect().
    startSimulationScenario(SimulatorScenario.idleBandSample);
    return true;
  }

  @override
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) async {
    _phaseSubject.add(SensorMonitoringPhase.calibratingIdleBand);
    startSimulationScenario(SimulatorScenario.idleBandSample);

    final acc = IdleBandAccumulator();
    // Skip the BehaviorSubject's replayed current value so a stale sample from
    // a prior scenario cannot widen the learned band.
    final sub = _signalSubject.stream.skip(1).listen(acc.add);
    await Future.delayed(window);
    unawaited(sub.cancel());

    final band = acc.band;
    if (band == null) {
      _phaseSubject.add(SensorMonitoringPhase.idle);
      throw StateError(
        'sampleIdleBand: no samples arrived on signalStream within $window',
      );
    }

    // Re-shape the still-running emitter to a band-spanning breathing wave so
    // the wear check observes strict excursions against the just-returned band
    // (idleBandSample's own range *is* the band and would yield zero cycles).
    startSimulationScenario(SimulatorScenario.normalRespiration);
    _phaseSubject.add(SensorMonitoringPhase.idle);
    return band;
  }

  @override
  void startMonitoringSession() {
    _phaseSubject.add(SensorMonitoringPhase.monitoring);
    startSimulationScenario(SimulatorScenario.normalRespiration);
  }

  @override
  void stopMonitoringSession() {
    // AD-12: the emitter runs until disconnect(); revert to a resting scenario
    // instead of stopping it (mirrors BLESensorDriver.stopMonitoringSession).
    startSimulationScenario(SimulatorScenario.idleBandSample);
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
      double signal;

      switch (scenario) {
        case SimulatorScenario.idleBandSample:
          // Resting band-forming signal ~0.25–0.35 (0.30 ± 0.05).
          signal = 0.30 + 0.05 * sin(_step * 3);
          break;
        case SimulatorScenario.normalRespiration:
          // 0.275 ± 0.2 → ~0.075–0.475: strictly crosses both bounds of a
          // band learned from idleBandSample (~0.25–0.35).
          signal = 0.275 + 0.2 * sin(_step * 1.6);
          break;
        case SimulatorScenario.inBandNoExcursion:
          // Flat, always inside the band — a stop-breathing stretch.
          signal = 0.30;
          break;
        case SimulatorScenario.recovery:
          // 0.275 ± 0.22 → ~0.055–0.495: resumed breathing that also strictly
          // crosses both band bounds (never parks above).
          signal = 0.275 + 0.22 * sin(_step * 2);
          break;
        case SimulatorScenario.none:
          signal = 0.30;
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
      _signalSubject = BehaviorSubject<double>.seeded(0.3);
    } else {
      _signalSubject.add(0.3);
    }
    if (_isSimulatorSubject.isClosed) {
      _isSimulatorSubject = BehaviorSubject<bool>.seeded(true);
    } else {
      _isSimulatorSubject.add(true);
    }
    if (_scenarioSubject.isClosed) {
      _scenarioSubject =
          BehaviorSubject<SimulatorScenario>.seeded(SimulatorScenario.none);
    } else {
      _scenarioSubject.add(SimulatorScenario.none);
    }
  }

  void dispose() {
    stopSimulation();
  }
}
