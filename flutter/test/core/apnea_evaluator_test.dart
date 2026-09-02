import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/monitoring/apnea_evaluator.dart';

void main() {
  group('ApneaEvaluator Unit Tests', () {
    late ApneaEvaluator evaluator;

    setUp(() {
      evaluator = ApneaEvaluator(threshold: 0.5);
    });

    tearDown(() {
      evaluator.dispose();
    });

    test('Signal above threshold remains in normal state', () {
      for (int i = 0; i < 50; i++) {
        evaluator.evaluateSignal(1.2);
      }
      expect(evaluator.state, equals(ApneaState.normal));
    });

    test('10 seconds drop (100 ticks @ 10Hz) triggers breachAlert state', () async {
      expectLater(
        evaluator.stateStream,
        emitsInOrder([ApneaState.breachAlert]),
      );

      for (int i = 0; i < 100; i++) {
        evaluator.evaluateSignal(0.1);
      }
      expect(evaluator.state, equals(ApneaState.breachAlert));
    });

    test('Patient safe acknowledgement silences alarm', () {
      for (int i = 0; i < 100; i++) {
        evaluator.evaluateSignal(0.1);
      }
      expect(evaluator.state, equals(ApneaState.breachAlert));

      evaluator.acknowledgePatientSafe();
      expect(evaluator.state, equals(ApneaState.patientSafe));
    });

    test('5 seconds continuous normal breathing auto-restores to patientSafe', () {
      for (int i = 0; i < 100; i++) {
        evaluator.evaluateSignal(0.1);
      }
      expect(evaluator.state, equals(ApneaState.breachAlert));

      for (int i = 0; i < 50; i++) {
        evaluator.evaluateSignal(1.5);
      }
      expect(evaluator.state, equals(ApneaState.patientSafe));
    });
  });
}
