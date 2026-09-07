import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/monitoring/idle_band.dart';

void main() {
  group('IdleBand', () {
    test('const ctor asserts lower <= upper', () {
      // ignore: prefer_const_constructors
      expect(() => IdleBand(lower: 0.4, upper: 0.2), throwsA(isA<AssertionError>()));
      expect(const IdleBand(lower: 0.2, upper: 0.4), isNotNull);
      expect(const IdleBand(lower: 0.3, upper: 0.3), isNotNull); // degenerate ok
    });

    test('fromSamples takes the running min/max of the iterable', () {
      final band = IdleBand.fromSamples([0.30, 0.28, 0.34, 0.31, 0.27, 0.33]);
      expect(band.lower, 0.27);
      expect(band.upper, 0.34);
    });

    test('fromSamples ignores non-finite samples', () {
      final band = IdleBand.fromSamples([double.nan, 0.30, double.infinity, 0.36, -double.infinity]);
      expect(band.lower, 0.30);
      expect(band.upper, 0.36);
    });

    test('fromSamples throws on an empty / all-non-finite iterable', () {
      expect(() => IdleBand.fromSamples(const []), throwsArgumentError);
      expect(() => IdleBand.fromSamples([double.nan]), throwsArgumentError);
    });

    test('isInBand is inclusive of both bounds', () {
      const band = IdleBand(lower: 0.25, upper: 0.35);
      expect(band.isInBand(0.25), isTrue);
      expect(band.isInBand(0.35), isTrue);
      expect(band.isInBand(0.30), isTrue);
      expect(band.isInBand(0.2499), isFalse);
      expect(band.isInBand(0.3501), isFalse);
    });

    test('width is 0 for a degenerate band', () {
      expect(const IdleBand(lower: 0.3, upper: 0.3).width, 0.0);
    });
  });

  group('IdleBandAccumulator', () {
    test('accumulates running min/max and only widens', () {
      final acc = IdleBandAccumulator();
      expect(acc.band, isNull);
      acc.add(0.30);
      expect(acc.band, const IdleBand(lower: 0.30, upper: 0.30));
      acc.add(0.34);
      acc.add(0.26);
      acc.add(0.31); // inside — does not narrow
      expect(acc.band, const IdleBand(lower: 0.26, upper: 0.34));
    });

    test('ignores non-finite samples', () {
      final acc = IdleBandAccumulator();
      acc.add(double.nan);
      expect(acc.band, isNull);
      acc.add(0.30);
      acc.add(double.infinity);
      expect(acc.band, const IdleBand(lower: 0.30, upper: 0.30));
    });
  });

  group('BreathExcursionDetector', () {
    test('a cycle needs BOTH a strict over-upper and a strict under-lower', () {
      const band = IdleBand(lower: 0.25, upper: 0.35);
      final d = BreathExcursionDetector(band);

      d.add(0.40); // strictly above upper -> inhale
      expect(d.validCycleCount, 0);
      d.add(0.20); // strictly below lower -> exhale -> cycle completes
      expect(d.validCycleCount, 1);

      d.add(0.50);
      d.add(0.10);
      expect(d.validCycleCount, 2);
    });

    test('a one-sided excursion never completes a cycle', () {
      const band = IdleBand(lower: 0.25, upper: 0.35);
      final d = BreathExcursionDetector(band);
      for (var i = 0; i < 50; i++) {
        d.add(0.60); // only ever above upper
      }
      expect(d.validCycleCount, 0);
    });

    test('touching a bound exactly is NOT a strict excursion', () {
      const band = IdleBand(lower: 0.25, upper: 0.35);
      final d = BreathExcursionDetector(band);
      d.add(0.35); // == upper, not strictly above
      d.add(0.25); // == lower, not strictly below
      expect(d.validCycleCount, 0);
    });

    test('add() returns true only on the tick that completes a cycle', () {
      const band = IdleBand(lower: 0.25, upper: 0.35);
      final d = BreathExcursionDetector(band);
      expect(d.add(0.40), isFalse);
      expect(d.add(0.20), isTrue);
      expect(d.add(0.40), isFalse);
    });

    test('degenerate band (lower == upper): an oscillating wave still completes cycles', () {
      const band = IdleBand(lower: 0.30, upper: 0.30);
      final d = BreathExcursionDetector(band);
      for (var i = 0; i < 10; i++) {
        d.add(0.31); // strictly above
        d.add(0.29); // strictly below
      }
      expect(d.validCycleCount, 10);
      // never divides by band width anywhere
      expect(band.width, 0.0);
    });

    test('isStopBreathingSample is inclusive of both bounds', () {
      const band = IdleBand(lower: 0.25, upper: 0.35);
      final d = BreathExcursionDetector(band);
      expect(d.isStopBreathingSample(0.25), isTrue);
      expect(d.isStopBreathingSample(0.35), isTrue);
      expect(d.isStopBreathingSample(0.30), isTrue);
      expect(d.isStopBreathingSample(0.40), isFalse);
      expect(d.isStopBreathingSample(0.10), isFalse);
    });

    test('non-finite samples are ignored', () {
      const band = IdleBand(lower: 0.25, upper: 0.35);
      final d = BreathExcursionDetector(band);
      expect(d.add(double.nan), isFalse);
      expect(d.add(double.infinity), isFalse);
      expect(d.validCycleCount, 0);
    });
  });
}
