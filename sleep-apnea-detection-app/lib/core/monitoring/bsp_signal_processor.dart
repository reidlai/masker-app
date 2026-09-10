import 'dart:math' as math;
import 'drift_and_noise_floor_envelope.dart';

/// Result of 256-Point FFT Respiration Spectral Analysis (PRD Section 3.7 / FR-7.3).
class SpectralAnalysisResult {
  /// Peak respiration frequency in Breaths Per Minute (BPM).
  final double respirationRateBpm;

  /// Peak respiration frequency in Hertz (Hz).
  final double peakFrequencyHz;

  /// Spectral magnitude at the peak frequency bin.
  final double peakMagnitude;

  /// Estimated Signal-to-Noise Ratio in decibels (dB).
  final double snrDb;

  /// FFT magnitude spectrum across all positive frequency bins (128 bins).
  final List<double> magnitudeSpectrum;

  const SpectralAnalysisResult({
    required this.respirationRateBpm,
    required this.peakFrequencyHz,
    required this.peakMagnitude,
    required this.snrDb,
    required this.magnitudeSpectrum,
  });

  @override
  String toString() =>
      'SpectralAnalysisResult(rate: ${respirationRateBpm.toStringAsFixed(1)} BPM, peak: ${peakFrequencyHz.toStringAsFixed(3)} Hz, SNR: ${snrDb.toStringAsFixed(1)} dB)';
}

/// Biomedical Signal Processor (BSP) for 10Hz BLE Telemetry Data (PRD Section 3.7).
///
/// Implements 256-point FFT spectral analysis, Hanning windowing, SNR estimation,
/// ADC telemetry signal conditioning, and noise floor bounding per FR-7.1–FR-7.4.
class BspSignalProcessor {
  /// Default sampling frequency ($f_s = 10\text{ Hz}$).
  final double samplingRateHz;

  /// FFT buffer size ($N_{\text{fft}} = 256$).
  static const int kFftSize = 256;

  const BspSignalProcessor({this.samplingRateHz = 10.0});

  /// Convert raw BLE ADC sample to calibrated bio-signal voltage (FR-7.4).
  ///
  /// Formula: $S[n] = \text{ADC}[n] \times \frac{V_{\text{ref}}}{2^N} - V_{\text{offset}}$
  static double quantizeAdcSample({
    required int rawAdc,
    double vRef = 3.3,
    int bitResolution = 12,
    double vOffset = 0.0,
  }) {
    final maxAdc = math.pow(2, bitResolution).toDouble();
    return (rawAdc * (vRef / maxAdc)) - vOffset;
  }

  /// Compute Peak-to-Peak Noise Floor ($V_{pp\_noise}$) for an Idle Band (FR-7.1).
  static double computeNoiseFloor(IdleBand band) => band.noiseFloor;

  /// Compute Signal-to-Noise Ratio (SNR in dB) between bio-signal amplitude and noise floor.
  static double computeSnrDb({
    required double signalAmplitude,
    required double noiseFloorAmplitude,
  }) {
    if (noiseFloorAmplitude <= 0.0 || signalAmplitude <= 0.0) return 0.0;
    final ratio = signalAmplitude / noiseFloorAmplitude;
    return 20.0 * (math.log(ratio) / math.ln10);
  }

  /// Compute 256-Point FFT Respiration Rate (BPM) from a sample buffer (FR-7.3).
  ///
  /// Accepts a buffer of raw samples (at least 256 samples). Pads with zero or truncates to 256.
  /// Applies a Hanning window: $w[n] = 0.5 \left( 1 - \cos\left(\frac{2\pi n}{N-1}\right)\right)$
  /// and calculates peak magnitude within physiological respiration band (4.0 to 40.0 BPM).
  SpectralAnalysisResult computeRespirationSpectrum(List<double> rawSamples) {
    // 1. Prepare 256-point buffer with Hanning window
    final List<double> windowed = List<double>.filled(kFftSize, 0.0);
    final int inputLen = math.min(rawSamples.length, kFftSize);

    // Compute mean to remove DC bias
    double mean = 0.0;
    int validCount = 0;
    for (int i = 0; i < inputLen; i++) {
      if (rawSamples[i].isFinite) {
        mean += rawSamples[i];
        validCount++;
      }
    }
    if (validCount > 0) mean /= validCount;

    for (int i = 0; i < inputLen; i++) {
      final double val = rawSamples[i].isFinite ? (rawSamples[i] - mean) : 0.0;
      // Hanning window function
      final double win = 0.5 * (1.0 - math.cos((2.0 * math.pi * i) / (kFftSize - 1)));
      windowed[i] = val * win;
    }

    // 2. Perform Radix-2 256-Point Complex FFT
    final List<double> real = List<double>.from(windowed);
    final List<double> imag = List<double>.filled(kFftSize, 0.0);
    _fftCooleyTukey(real, imag);

    // 3. Calculate Magnitude Spectrum (positive frequencies: 0 to N/2 - 1)
    final int halfSize = kFftSize ~/ 2;
    final List<double> magnitudes = List<double>.filled(halfSize, 0.0);
    for (int i = 0; i < halfSize; i++) {
      magnitudes[i] = math.sqrt(real[i] * real[i] + imag[i] * imag[i]);
    }

    // 4. Find peak index in physiological range (4.0 BPM to 40.0 BPM)
    // Frequency per bin = fs / N = 10 / 256 = 0.0390625 Hz (2.34375 BPM per bin)
    final double minHz = 4.0 / 60.0; // 0.0667 Hz
    final double maxHz = 40.0 / 60.0; // 0.667 Hz

    final int minBin = (minHz * kFftSize / samplingRateHz).ceil().clamp(1, halfSize - 1);
    final int maxBin = (maxHz * kFftSize / samplingRateHz).floor().clamp(minBin, halfSize - 1);

    int maxBinIdx = minBin;
    double maxMag = 0.0;
    double totalPower = 0.0;

    for (int i = 1; i < halfSize; i++) {
      totalPower += magnitudes[i] * magnitudes[i];
      if (i >= minBin && i <= maxBin) {
        if (magnitudes[i] > maxMag) {
          maxMag = magnitudes[i];
          maxBinIdx = i;
        }
      }
    }

    final double peakHz = maxBinIdx * (samplingRateHz / kFftSize);
    final double rateBpm = peakHz * 60.0;

    // Calculate SNR (Peak power vs average power in remaining spectrum)
    final double peakPower = maxMag * maxMag;
    final double noisePower = (totalPower - peakPower).clamp(0.0001, double.infinity) / (halfSize - 1);
    final double snrDb = 10.0 * (math.log(peakPower / noisePower) / math.ln10);

    return SpectralAnalysisResult(
      respirationRateBpm: rateBpm,
      peakFrequencyHz: peakHz,
      peakMagnitude: maxMag,
      snrDb: snrDb.isFinite ? snrDb : 0.0,
      magnitudeSpectrum: magnitudes,
    );
  }

  /// Cooley-Tukey Radix-2 In-Place Decimation-in-Time FFT
  static void _fftCooleyTukey(List<double> real, List<double> imag) {
    final int n = real.length;

    // Bit reversal permutation
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      if (i < j) {
        final tempR = real[i];
        real[i] = real[j];
        real[j] = tempR;
        final tempI = imag[i];
        imag[i] = imag[j];
        imag[j] = tempI;
      }
      int k = n >> 1;
      while (k <= j) {
        j -= k;
        k >>= 1;
      }
      j += k;
    }

    // Butterfly computations
    for (int len = 2; len <= n; len <<= 1) {
      final double angle = -2.0 * math.pi / len;
      final double wlenR = math.cos(angle);
      final double wlenI = math.sin(angle);

      for (int i = 0; i < n; i += len) {
        double wR = 1.0;
        double wI = 0.0;
        for (int k = 0; k < len / 2; k++) {
          final int u = i + k;
          final int v = i + k + len ~/ 2;

          final double uR = real[u];
          final double uI = imag[u];
          final double vR = real[v] * wR - imag[v] * wI;
          final double vI = real[v] * wI + imag[v] * wR;

          real[u] = uR + vR;
          imag[u] = uI + vI;
          real[v] = uR - vR;
          imag[v] = uI - vI;

          final double nextWR = wR * wlenR - wI * wlenI;
          final double nextWI = wR * wlenI + wI * wlenR;
          wR = nextWR;
          wI = nextWI;
        }
      }
    }
  }
}
