import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/monitoring/apnea_evaluator.dart';
import 'package:masker_app/core/monitoring/idle_band.dart';

void main() {
  group('ApneaEvaluator (IDLE Band model)', () {
    const band = IdleBand(lower: 0.25, upper: 0.35);
    late ApneaEvaluator evaluator;

    setUp(() {
      evaluator = ApneaEvaluator(idleBand: band);
    });

    tearDown(() {
      evaluator.dispose();
    });

    test('out-of-band excursions keep the state normal', () {
      for (int i = 0; i < 200; i++) {
        evaluator.evaluateSignal(i.isEven ? 0.60 : 0.05); // strict cross both bounds
      }
      expect(evaluator.state, equals(ApneaState.normal));
    });

    test('10 s of in-band stop-breathing samples (100 ticks) triggers breachAlert', () async {
      expectLater(evaluator.stateStream, emitsInOrder([ApneaState.breachAlert]));
      for (int i = 0; i < 100; i++) {
        evaluator.evaluateSignal(0.30); // inside [0.25, 0.35], no cycle completes
      }
      expect(evaluator.state, equals(ApneaState.breachAlert));
    });

    test('a sample resting exactly on a bound is a stop-breathing sample', () {
      for (int i = 0; i < 100; i++) {
        evaluator.evaluateSignal(i.isEven ? 0.25 : 0.35); // both inclusive-in-band
      }
      expect(evaluator.state, equals(ApneaState.breachAlert));
    });

    test('patient-safe acknowledgement silences the alarm', () {
      for (int i = 0; i < 100; i++) {
        evaluator.evaluateSignal(0.30);
      }
      expect(evaluator.state, equals(ApneaState.breachAlert));
      evaluator.acknowledgePatientSafe();
      expect(evaluator.state, equals(ApneaState.patientSafe));
    });

    test('5 s of resumed valid excursions (50 ticks) auto-silences after a breach', () {
      for (int i = 0; i < 100; i++) {
        evaluator.evaluateSignal(0.30);
      }
      expect(evaluator.state, equals(ApneaState.breachAlert));
      for (int i = 0; i < 60; i++) {
        evaluator.evaluateSignal(i.isEven ? 0.60 : 0.05); // resumed excursions
      }
      expect(evaluator.state, equals(ApneaState.patientSafe));
    });

    test('a realistic breathing wave that dips through the band still '
        'auto-silences within ~5 s after a breach', () {
      for (int i = 0; i < 100; i++) {
        evaluator.evaluateSignal(0.30);
      }
      expect(evaluator.state, equals(ApneaState.breachAlert));

      // 0.30 ± 0.2 sine — crosses both bounds each cycle AND spends a few
      // ticks inside [0.25, 0.35] between breaths, like the real simulator
      // shapes. Auto-silence must still fire.
      double step = 0.0;
      for (int i = 0; i < 90; i++) {
        step += 0.1;
        evaluator.evaluateSignal(0.30 + 0.2 * sin(step * 1.6));
      }
      expect(evaluator.state, equals(ApneaState.patientSafe));
    });

    test('non-finite samples are ignored (no state change, no crash)', () {
      for (int i = 0; i < 100; i++) {
        evaluator.evaluateSignal(double.nan);
      }
      evaluator.evaluateSignal(double.infinity);
      expect(evaluator.state, equals(ApneaState.normal));
    });

    test('a degenerate band still trips a breach on flat in-band samples', () {
      final e = ApneaEvaluator(idleBand: const IdleBand(lower: 0.30, upper: 0.30));
      for (int i = 0; i < 100; i++) {
        e.evaluateSignal(0.30); // == both bounds -> in band -> stop tick
      }
      expect(e.state, equals(ApneaState.breachAlert));
      e.dispose();
    });
  });
}
