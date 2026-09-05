import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_sensor_driver.dart';

void main() {
  group('BLESensorDriver Unit Tests', () {
    late BLESensorDriver driver;

    setUp(() {
      driver = BLESensorDriver();
    });

    tearDown(() {
      driver.disconnect();
    });

    test('Initial state is disconnected', () {
      expect(driver.state, equals(BLEDeviceState.disconnected));
    });

    test('scanAndConnect transitions state to connected', () async {
      final Future<bool> connectFuture = driver.scanAndConnect();
      expect(driver.state, equals(BLEDeviceState.scanning));
      bool success = await connectFuture;
      expect(success, isTrue);
      expect(driver.state, equals(BLEDeviceState.connected));
    });

    test('Stage 1 room noise calibration computes positive N_idle floor', () async {
      double nIdle = await driver.calibrateStage1NoiseCeiling();
      expect(nIdle, greaterThan(0.0));
      expect(driver.ambientNoiseFloor, equals(nIdle));
    });

    test('Stage 2 training calibration computes signal threshold as 10% of V_pp', () async {
      await driver.calibrateStage1NoiseCeiling();
      await driver.startTrainingCalibration();
      double threshold = await driver.stopTrainingCalibration();
      expect(threshold, equals(0.10 * driver.breathBaselineVpp));
      expect(driver.signalThreshold, equals(threshold));
    });
  });
}
