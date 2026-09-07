import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../monitoring/drift_and_noise_floor_envelope.dart';
import 'i_ble_sensor_driver.dart';
import 'ble_simulator_driver.dart';
import 'ble_sensor_driver.dart';

/// App-boot background BLE receiver service managing active [IBLESensorDriver]
/// and exposing a unified RxDart [BehaviorSubject<double>] reactive stream queue.
class BleReceiverService implements IBLESensorDriver {
  // Dart Singleton Pattern:
  // _instance lazily instantiates the single global instance using the private named constructor _internal().
  static final BleReceiverService _instance = BleReceiverService._internal();

  // Factory constructor returns the cached static _instance whenever BleReceiverService() is called,
  // guaranteeing a single shared background stream queue across the entire app lifecycle.
  factory BleReceiverService() => _instance;

  IBLESensorDriver _activeDriver;
  // Neutral resting seed (raw signal units). The queue must expose *some*
  // value to a late subscriber before the first real 10 Hz sample arrives; a
  // small positive resting value keeps the waveform renderer well-defined
  // without implying any calibrated reference.
  BehaviorSubject<double> _thermalSubject = BehaviorSubject<double>.seeded(0.3);
  StreamSubscription<double>? _driverSubscription;

  static const bool _isDevMode = bool.fromEnvironment('DEV_MODE', defaultValue: false);

  // Private named constructor:
  // Dynamically selects initial driver based on compile-time environment flag.
  // Production (DEV_MODE=false) defaults to physical hardware BLESensorDriver().
  // Developer Mode (DEV_MODE=true) defaults to BleSimulatorDriver() for simulator testing.
  BleReceiverService._internal()
      : _activeDriver = _isDevMode ? BleSimulatorDriver() : BLESensorDriver() {
    _initializeStream();
  }

  /// Construct with explicit driver for testing or custom DI
  BleReceiverService.withDriver(IBLESensorDriver driver)
      : _activeDriver = driver {
    _initializeStream();
  }

  IBLESensorDriver get activeDriver => _activeDriver;

  void setActiveDriver(IBLESensorDriver driver) {
    _driverSubscription?.cancel();
    _activeDriver = driver;
    _initializeStream();
  }

  void _initializeStream() {
    _driverSubscription?.cancel();
    if (_thermalSubject.isClosed) {
      _thermalSubject = BehaviorSubject<double>.seeded(0.3);
    }
    _driverSubscription = _activeDriver.signalStream.listen(
      (double val) {
        if (!_thermalSubject.isClosed) {
          _thermalSubject.add(val);
        }
      },
      onError: (err) {
        if (!_thermalSubject.isClosed) {
          _thermalSubject.addError(err);
        }
      },
    );
  }

  @override
  Stream<double> get signalStream {
    if (_thermalSubject.isClosed) {
      _initializeStream();
    }
    return _thermalSubject.stream;
  }

  ValueStream<double> get reactiveStream {
    if (_thermalSubject.isClosed) {
      _initializeStream();
    }
    return _thermalSubject.stream;
  }

  @override
  SensorMonitoringPhase get currentPhase => _activeDriver.currentPhase;

  @override
  Stream<SensorMonitoringPhase> get phaseStream => _activeDriver.phaseStream;

  @override
  Future<bool> scanAndConnect() async {
    return await _activeDriver.scanAndConnect();
  }

  // --- IDLE Band Calibration (AD-04) ---
  @override
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) {
    return _activeDriver.sampleIdleBand(window: window);
  }

  // --- Nocturnal Monitoring Lifecycle ---
  @override
  void startMonitoringSession() {
    _activeDriver.startMonitoringSession();
  }

  @override
  void stopMonitoringSession() {
    _activeDriver.stopMonitoringSession();
  }

  @override
  void disconnect() {
    _activeDriver.disconnect();
  }

  void resetForTest() {
    _driverSubscription?.cancel();
    if (!_thermalSubject.isClosed) {
      _thermalSubject.close();
    }
    _thermalSubject = BehaviorSubject<double>.seeded(0.3);
    _activeDriver = BleSimulatorDriver();
    BleSimulatorDriver().resetForTest();
    _initializeStream();
  }

  void dispose() {
    _driverSubscription?.cancel();
    if (!_thermalSubject.isClosed) {
      _thermalSubject.close();
    }
  }
}
