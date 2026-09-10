import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/monitoring/bsp_signal_processor.dart';
import 'package:masker_app/core/monitoring/drift_and_noise_floor_envelope.dart';

void main() {
  group('BspSignalProcessor', () {
    const processor = BspSignalProcessor(samplingRateHz: 10.0);

    test('quantizeAdcSample converts raw ADC integer to voltage', () {
      final v0 = BspSignalProcessor.quantizeAdcSample(
        rawAdc: 0,
        vRef: 3.3,
        bitResolution: 12,
      );
      expect(v0, closeTo(0.0, 0.001));

      final vMid = BspSignalProcessor.quantizeAdcSample(
        rawAdc: 2048,
        vRef: 3.3,
        bitResolution: 12,
      );
      expect(vMid, closeTo(1.65, 0.01));

      final vMax = BspSignalProcessor.quantizeAdcSample(
        rawAdc: 4095,
        vRef: 3.3,
        bitResolution: 12,
      );
      expect(vMax, closeTo(3.3, 0.01));
    });

    test('computeNoiseFloor & computeSnrDb calculate noise and SNR', () {
      const band = IdleBand(lower: 0.2, upper: 0.6);
      expect(BspSignalProcessor.computeNoiseFloor(band), closeTo(0.4, 0.0001));

      final snr = BspSignalProcessor.computeSnrDb(
        signalAmplitude: 4.0,
        noiseFloorAmplitude: 0.4,
      );
      // 20 * log10(10) = 20.0 dB
      expect(snr, closeTo(20.0, 0.1));
    });

    test('computeRespirationSpectrum extracts correct respiration rate (BPM) for a 16 BPM sine wave', () {
      // 16 BPM = 16 / 60 = 0.2667 Hz
      const double targetBpm = 16.0;
      const double targetFreqHz = targetBpm / 60.0;
      const double fs = 10.0;
      const int numSamples = 256;

      final samples = List<double>.generate(numSamples, (i) {
        final t = i / fs;
        return 1.5 * math.sin(2.0 * math.pi * targetFreqHz * t);
      });

      final result = processor.computeRespirationSpectrum(samples);

      // Bin resolution = 10 / 256 = 0.039 Hz = ~2.34 BPM
      expect(result.respirationRateBpm, closeTo(targetBpm, 2.5));
      expect(result.peakFrequencyHz, closeTo(targetFreqHz, 0.04));
      expect(result.snrDb, greaterThan(10.0));
      expect(result.magnitudeSpectrum.length, equals(128));
    });

    test('computeRespirationSpectrum extracts correct respiration rate (BPM) for a 12 BPM sine wave', () {
      // 12 BPM = 12 / 60 = 0.20 Hz
      const double targetBpm = 12.0;
      const double targetFreqHz = targetBpm / 60.0;
      const double fs = 10.0;
      const int numSamples = 256;

      final samples = List<double>.generate(numSamples, (i) {
        final t = i / fs;
        return 2.0 * math.sin(2.0 * math.pi * targetFreqHz * t);
      });

      final result = processor.computeRespirationSpectrum(samples);

      expect(result.respirationRateBpm, closeTo(targetBpm, 2.5));
      expect(result.snrDb, greaterThan(10.0));
    });
  });
}
