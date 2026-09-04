import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'i_ble_sensor_driver.dart';
import 'ble_telemetry_service.dart';
import 'ble_sensor_driver.dart';

/// App-boot background BLE receiver service managing active [IBLESensorDriver]
/// and exposing a unified RxDart [BehaviorSubject<double>] reactive stream queue.
class BleReceiverService implements IBLESensorDriver {
  static final BleReceiverService _instance = BleReceiverService._internal();
  factory BleReceiverService() => _instance;

  IBLESensorDriver _activeDriver;
  BehaviorSubject<double> _thermalSubject = BehaviorSubject<double>.seeded(5.0);
  StreamSubscription<double>? _driverSubscription;

  BleReceiverService._internal() : _activeDriver = BleTelemetryService() {
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
      _thermalSubject = BehaviorSubject<double>.seeded(5.0);
    }
    _driverSubscription = _activeDriver.thermalStream.listen(
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
  Stream<double> get thermalStream {
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
  double get apneaThreshold => _activeDriver.apneaThreshold;

  @override
  Future<bool> scanAndConnect() async {
    return await _activeDriver.scanAndConnect();
  }

  @override
  Future<double> calibrateStage1NoiseFloor() async {
    return await _activeDriver.calibrateStage1NoiseFloor();
  }

  @override
  Future<double> calibrateStage2ActiveBreath() async {
    return await _activeDriver.calibrateStage2ActiveBreath();
  }

  @override
  void startTelemetryLogging() {
    _activeDriver.startTelemetryLogging();
  }

  @override
  void stopTelemetryLogging() {
    _activeDriver.stopTelemetryLogging();
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
    _thermalSubject = BehaviorSubject<double>.seeded(5.0);
    _activeDriver = BleTelemetryService();
    BleTelemetryService().resetForTest();
    _initializeStream();
  }

  void dispose() {
    _driverSubscription?.cancel();
    if (!_thermalSubject.isClosed) {
      _thermalSubject.close();
    }
  }
}
