import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_sensor_driver.dart';
import 'package:masker_app/core/monitoring/idle_band.dart';

void main() {
  group('BLESensorDriver (IDLE Band)', () {
    test('Initial state is disconnected', () {
      final driver = BLESensorDriver();
      expect(driver.state, equals(BLEDeviceState.disconnected));
      driver.disconnect();
    });

    test('scanAndConnect connects and starts a continuous emitter', () {
      fakeAsync((async) {
        final driver = BLESensorDriver();
        bool? result;
        driver.scanAndConnect().then((v) => result = v);
        async.elapse(const Duration(seconds: 2));

        expect(result, isTrue);
        expect(driver.state, equals(BLEDeviceState.connected));

        final seen = <double>[];
        final sub = driver.signalStream.listen(seen.add);
        async.elapse(const Duration(seconds: 1));
        expect(seen, isNotEmpty, reason: 'signalStream must be live after scanAndConnect');

        sub.cancel();
        driver.disconnect();
      });
    });

    test('sampleIdleBand returns the running min/max of the resting sample', () {
      fakeAsync((async) {
        final driver = BLESensorDriver();
        driver.scanAndConnect();
        async.elapse(const Duration(seconds: 2));

        IdleBand? band;
        driver
            .sampleIdleBand(window: const Duration(seconds: 2))
            .then((b) => band = b);
        async.elapse(const Duration(seconds: 3));

        expect(band, isNotNull);
        expect(band!.lower, lessThanOrEqualTo(band!.upper));
        expect(band!.lower, greaterThan(0.25));
        expect(band!.upper, lessThan(0.35));

        driver.disconnect();
      });
    });

    test('sampleIdleBand throws StateError when no sample arrives', () {
      fakeAsync((async) {
        // Never connected -> the emitter was never started -> the stream is silent.
        final driver = BLESensorDriver();
        Object? err;
        driver
            .sampleIdleBand(window: const Duration(seconds: 1))
            .catchError((e) {
          err = e;
          return const IdleBand(lower: 0, upper: 0);
        });
        async.elapse(const Duration(seconds: 2));
        expect(err, isA<StateError>());
        driver.disconnect();
      });
    });

    test('after sampleIdleBand the still-live stream strictly spans the returned '
        'band — >= 2 valid cycles within kWearCheckWindow', () {
      fakeAsync((async) {
        final driver = BLESensorDriver();
        driver.scanAndConnect();
        async.elapse(const Duration(seconds: 2));

        IdleBand? band;
        driver
            .sampleIdleBand(window: const Duration(seconds: 2))
            .then((b) => band = b);
        async.elapse(const Duration(seconds: 3));
        expect(band, isNotNull);

        final detector = BreathExcursionDetector(band!);
        final sub = driver.signalStream.listen(detector.add);
        async.elapse(kWearCheckWindow);
        sub.cancel();

        expect(detector.validCycleCount, greaterThanOrEqualTo(2));

        driver.disconnect();
      });
    });

    test('stopMonitoringSession keeps the emitter live (AD-12)', () {
      fakeAsync((async) {
        final driver = BLESensorDriver();
        driver.scanAndConnect();
        async.elapse(const Duration(seconds: 2));
        driver.startMonitoringSession();
        async.elapse(const Duration(milliseconds: 300));
        driver.stopMonitoringSession();

        final seen = <double>[];
        final sub = driver.signalStream.listen(seen.add);
        async.elapse(const Duration(seconds: 1));
        expect(seen, isNotEmpty);

        sub.cancel();
        driver.disconnect();
      });
    });
  });
}
