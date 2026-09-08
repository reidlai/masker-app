import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/core/monitoring/apnea_evaluator.dart';
import 'package:masker_app/core/monitoring/drift_and_noise_floor_envelope.dart';

void main() {
  tearDown(() => BleSimulatorDriver().resetForTest());

  test('sampleIdleBand -> ApneaEvaluator: In-Band trips a breach, valid '
      'excursions never do', () {
    fakeAsync((async) {
      final driver = BleSimulatorDriver();
      driver.resetForTest();
      driver.scanAndConnect();
      async.elapse(const Duration(milliseconds: 200));

      IdleBand? band;
      driver
          .sampleIdleBand(window: const Duration(seconds: 2))
          .then((b) => band = b);
      async.elapse(const Duration(seconds: 3));
      expect(band, isNotNull);
      expect(band!.lower, lessThanOrEqualTo(band!.upper));

      // In-band, no excursion -> breachAlert after ~100 ticks.
      final breachEval = ApneaEvaluator(idleBand: band!);
      final mid = (band!.lower + band!.upper) / 2;
      for (var i = 0; i < 110; i++) {
        breachEval.evaluateSignal(mid);
      }
      expect(breachEval.state, equals(ApneaState.breachAlert));
      breachEval.dispose();

      // Resumed valid excursions -> stays normal, never breaches.
      final normalEval = ApneaEvaluator(idleBand: band!);
      for (var i = 0; i < 300; i++) {
        normalEval.evaluateSignal(i.isEven ? band!.upper + 0.2 : band!.lower - 0.2);
      }
      expect(normalEval.state, equals(ApneaState.normal));
      normalEval.dispose();

      driver.resetForTest();
    });
  });

  test('the emitter stays live after sampleIdleBand and after '
      'stopMonitoringSession (AD-12)', () {
    fakeAsync((async) {
      final driver = BleSimulatorDriver();
      driver.resetForTest();
      driver.scanAndConnect();
      async.elapse(const Duration(milliseconds: 200));

      driver.sampleIdleBand(window: const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 2));

      final afterSample = <double>[];
      final sub1 = driver.signalStream.listen(afterSample.add);
      async.elapse(const Duration(seconds: 1));
      expect(afterSample, isNotEmpty, reason: 'stream must stay live after sampleIdleBand');
      sub1.cancel();

      driver.startMonitoringSession();
      async.elapse(const Duration(milliseconds: 300));
      driver.stopMonitoringSession();

      final afterStop = <double>[];
      final sub2 = driver.signalStream.listen(afterStop.add);
      async.elapse(const Duration(seconds: 1));
      expect(afterStop, isNotEmpty, reason: 'stopMonitoringSession must not stop the emitter');
      sub2.cancel();

      driver.resetForTest();
    });
  });

  test('after sampleIdleBand the live stream strictly spans the returned band '
      '(>= 2 cycles within kWearCheckWindow)', () {
    fakeAsync((async) {
      final driver = BleSimulatorDriver();
      driver.resetForTest();
      driver.scanAndConnect();
      async.elapse(const Duration(milliseconds: 200));

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

      driver.resetForTest();
    });
  });
}
