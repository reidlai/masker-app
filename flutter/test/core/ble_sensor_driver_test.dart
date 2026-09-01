import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/ble/ble_sensor_driver.dart';

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
      double nIdle = await driver.calibrateStage1NoiseFloor();
      expect(nIdle, isGreaterThan(0.0));
      expect(driver.ambientNoiseFloor, equals(nIdle));
    });

    test('Stage 2 active breath calibration computes apnea threshold as 10% of V_pp', () async {
      await driver.calibrateStage1NoiseFloor();
      double threshold = await driver.calibrateStage2ActiveBreath();
      expect(threshold, equals(0.10 * driver.breathBaselineVpp));
      expect(driver.apneaThreshold, equals(threshold));
    });
  });
}
