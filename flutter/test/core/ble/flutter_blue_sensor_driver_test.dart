import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/flutter_blue_sensor_driver.dart';
import 'package:masker_app/core/ble/i_ble_sensor_driver.dart';
import 'package:masker_app/core/monitoring/drift_and_noise_floor_envelope.dart';

void main() {
  // No real GATT characteristic in a unit test, so sampleIdleBand takes the
  // synthetic-fallback path (CI / simulator-on-device).
  group('FlutterBlueSensorDriver synthetic fallback', () {
    test('sampleIdleBand returns a valid band from the resting fallback', () {
      fakeAsync((async) {
        final driver = FlutterBlueSensorDriver();
        IdleBand? band;
        driver
            .sampleIdleBand(window: const Duration(seconds: 2))
            .then((b) => band = b);
        async.elapse(const Duration(seconds: 3));

        expect(band, isNotNull);
        expect(band!.lower, lessThanOrEqualTo(band!.upper));
        expect(band!.lower, greaterThan(0.25));
        expect(band!.upper, lessThan(0.35));
        expect(driver.currentPhase, equals(SensorMonitoringPhase.idle));

        driver.disconnect();
      });
    });

    test('the fallback keeps emitting after sampleIdleBand and strictly spans '
        'the returned band — >= 2 cycles within kWearCheckWindow', () {
      fakeAsync((async) {
        final driver = FlutterBlueSensorDriver();
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

    test('sampleIdleBand throws StateError if the fallback never produces a sample', () {
      fakeAsync((async) {
        final driver = FlutterBlueSensorDriver();
        Object? err;
        driver
            .sampleIdleBand(window: Duration.zero)
            .catchError((e) {
          err = e;
          return const IdleBand(lower: 0, upper: 0);
        });
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 10));
        expect(err, isA<StateError>());
        driver.disconnect();
      });
    });
  });
}
