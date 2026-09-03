import 'dart:async';
import 'dart:math';
import 'i_ble_sensor_driver.dart';

enum BLEDeviceState { disconnected, scanning, connecting, connected }

class BLESensorDriver implements IBLESensorDriver {
  static const String serviceUuid = "0x180D";
  static const String characteristicUuid = "0x2A37";

  BLEDeviceState _state = BLEDeviceState.disconnected;
  BLEDeviceState get state => _state;

  StreamController<double>? _thermalStreamController;
  @override
  Stream<double> get thermalStream {
    _thermalStreamController ??= StreamController<double>.broadcast();
    return _thermalStreamController!.stream;
  }

  Timer? _telemetryTimer;
  double _ambientNoiseFloor = 0.5; // N_idle
  double _breathBaselineVpp = 5.0; // V_pp
  double _apneaThreshold = 0.5;    // 0.10 * V_pp

  double get ambientNoiseFloor => _ambientNoiseFloor;
  double get breathBaselineVpp => _breathBaselineVpp;

  @override
  double get apneaThreshold => _apneaThreshold;

  @override
  Future<bool> scanAndConnect() async {
    _state = BLEDeviceState.scanning;
    await Future.delayed(const Duration(milliseconds: 600));
    _state = BLEDeviceState.connecting;
    await Future.delayed(const Duration(milliseconds: 600));
    _state = BLEDeviceState.connected;
    return true;
  }

  // Stage 1 Calibration: Sample idle room temperature noise (N_idle)
  @override
  Future<double> calibrateStage1NoiseFloor() async {
    double noiseSum = 0.0;
    final Random rnd = Random();
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      noiseSum += 0.3 + (rnd.nextDouble() * 0.2); // ~0.4°C noise
    }
    _ambientNoiseFloor = noiseSum / 10.0;
    return _ambientNoiseFloor;
  }

  // Stage 2 Calibration: Sample active breathing thermal training (Delta T)
  @override
  Future<double> calibrateStage2ActiveBreath() async {
    double maxBreath = 0.0;
    final Random rnd = Random();
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      double sample = 4.5 + (rnd.nextDouble() * 1.5); // ~5.0°C active breath
      if (sample > maxBreath) maxBreath = sample;
    }
    _breathBaselineVpp = maxBreath;
    _apneaThreshold = 0.10 * _breathBaselineVpp;
    return _apneaThreshold;
  }

  @override
  void startTelemetryLogging() {
    _telemetryTimer?.cancel();
    double step = 0.0;
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      step += 0.1;
      // 10Hz sine wave simulating thermal breath stream
      double signal = (_breathBaselineVpp / 2) * (1 + sin(step)) + _ambientNoiseFloor;
      _thermalStreamController?.add(signal);
    });
  }

  @override
  void stopTelemetryLogging() {
    _telemetryTimer?.cancel();
  }

  @override
  void disconnect() {
    stopTelemetryLogging();
    _thermalStreamController?.close();
    _thermalStreamController = null;
    _state = BLEDeviceState.disconnected;
  }
}
