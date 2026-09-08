/// Single-stage Sensor Baseline Drift & Noise Floor Envelope signal model (PRD v2.5.0 / AD-04).
///
/// Pure Dart — no Flutter imports. Reused by the calibration wizard,
/// the wear check, [ApneaEvaluator], the developer simulator, and (Epic 3) the
/// deeper on-device evaluator rework, so the pieces never diverge on how the
/// band is built or what counts as a breath.
library;

/// Idle-sample window default (`[ASSUMPTION]`, tunable 5–30 s).
const Duration kIdleSampleWindow = Duration(seconds: 10);

/// Wear-check window default (`[ASSUMPTION]`).
const Duration kWearCheckWindow = Duration(seconds: 25);

/// Valid breath-excursion cycles the wear check must observe before
/// "Start Sleep Monitoring" unlocks (AD-05).
const int kRequiredValidCycles = 2;

/// Immutable session Sensor Baseline Drift & Noise Floor Envelope:
/// the running `min`/`max` of a worn idle sample.
///
/// Works in raw signal units end to end — there is no thermal-to-volumetric
/// (L/s) transform, no `V_pp` peak-to-peak baseline, and no `0.10 × V_pp`
/// threshold anywhere in this model. The band only ever widens within the
/// idle window and no margin is applied.
class IdleBand {
  /// Lower bound — the running minimum of the idle sample.
  final double lower;

  /// Upper bound — the running maximum of the idle sample.
  final double upper;

  const IdleBand({required this.lower, required this.upper})
      : assert(lower <= upper, 'IdleBand requires lower <= upper');

  /// Build a band from the running min/max of a sample iterable.
  ///
  /// Non-finite samples are ignored. Throws [ArgumentError] if the iterable
  /// yields no finite sample. Kept as documented public surface for Epic 3
  /// reuse even though production accumulation goes through
  /// [IdleBandAccumulator] — it is intentionally tested, not dead code.
  factory IdleBand.fromSamples(Iterable<double> samples) {
    double? lo;
    double? hi;
    for (final s in samples) {
      if (!s.isFinite) continue;
      if (lo == null || s < lo) lo = s;
      if (hi == null || s > hi) hi = s;
    }
    if (lo == null || hi == null) {
      throw ArgumentError.value(
        samples,
        'samples',
        'IdleBand.fromSamples requires at least one finite sample',
      );
    }
    return IdleBand(lower: lo, upper: hi);
  }

  /// Band width / Noise Floor Amplitude ($V_{pp\_noise} = \text{upper} - \text{lower}$).
  /// `0.0` for a degenerate band (`lower == upper`). Never used as a divisor anywhere.
  double get width => upper - lower;

  /// Alias for [width] representing the peak-to-peak Noise Floor Amplitude ($V_{pp\_noise}$)
  /// per PRD Section 3.7 (FR-7.1).
  double get noiseFloor => width;

  /// Build a band using percentile trimming to filter motion/glitch outliers.
  ///
  /// Filters non-finite values, sorts finite samples, and selects bounds at
  /// `trimPercent` (default 5%, i.e. 5th and 95th percentiles).
  factory IdleBand.fromSamplesTrimmed(Iterable<double> samples, {double trimPercent = 0.05}) {
    final valid = samples.where((s) => s.isFinite).toList()..sort();
    if (valid.isEmpty) {
      throw ArgumentError.value(
        samples,
        'samples',
        'IdleBand.fromSamplesTrimmed requires at least one finite sample',
      );
    }
    final int lowIndex = (valid.length * trimPercent).floor().clamp(0, valid.length - 1);
    final int highIndex = ((valid.length - 1) - (valid.length * trimPercent).floor()).clamp(lowIndex, valid.length - 1);
    final double lo = valid[lowIndex];
    final double hi = valid[highIndex];
    return IdleBand(lower: lo, upper: hi);
  }

  /// Inclusive of both bounds — the "stop-breathing" region.
  bool isInBand(double value) => value >= lower && value <= upper;

  @override
  bool operator ==(Object other) =>
      other is IdleBand && other.lower == lower && other.upper == upper;

  @override
  int get hashCode => Object.hash(lower, upper);

  @override
  String toString() => 'IdleBand(lower: $lower, upper: $upper)';
}

/// Accumulates the running `min`/`max` of the raw signal during the idle
/// window. The band only widens; it is never narrowed and no margin is added.
class IdleBandAccumulator {
  double? _min;
  double? _max;

  /// Feed one raw sample. Non-finite samples (`NaN` / `±inf`) are ignored so a
  /// glitch packet cannot poison the band.
  void add(double value) {
    if (!value.isFinite) return;
    if (_min == null || value < _min!) _min = value;
    if (_max == null || value > _max!) _max = value;
  }

  /// True once at least one finite sample has been accumulated.
  bool get hasSamples => _min != null && _max != null;

  /// The band learned so far, or `null` if no finite sample has arrived yet
  /// (e.g. the stream stayed silent for the whole window).
  IdleBand? get band =>
      hasSamples ? IdleBand(lower: _min!, upper: _max!) : null;

  void reset() {
    _min = null;
    _max = null;
  }
}

/// Detects valid Sensor Baseline & Noise Envelope breath-excursion cycles (AD-04 / AD-05).
///
/// A cycle completes when, since the last completion, the signal has gone
/// **strictly above** [IdleBand.upper] (inhale) **and strictly below**
/// [IdleBand.lower] (exhale). A phase that crosses only one bound does not
/// count. Excursion comparisons are strict (`>` / `<`); the in-band /
/// stop-breathing predicate ([isStopBreathingSample]) is inclusive of both
/// bounds. This asymmetry is deliberate: a signal whose own min/max *is* the
/// band never strictly leaves it, so the wear check can only pass once the
/// emitter is re-shaped to overshoot the learned band on both sides.
class BreathExcursionDetector {
  final IdleBand band;

  bool _sawInhale = false;
  bool _sawExhale = false;
  int _validCycleCount = 0;

  BreathExcursionDetector(this.band);

  /// Number of completed valid breath-excursion cycles observed so far.
  int get validCycleCount => _validCycleCount;

  /// Feed one sample. Non-finite samples are ignored. Returns `true` iff this
  /// sample completed a cycle.
  bool add(double value) {
    if (!value.isFinite) return false;
    if (value > band.upper) _sawInhale = true;
    if (value < band.lower) _sawExhale = true;
    if (_sawInhale && _sawExhale) {
      _validCycleCount++;
      _sawInhale = false;
      _sawExhale = false;
      return true;
    }
    return false;
  }

  /// A "stop-breathing" sample: resting inside `[lower, upper]` (inclusive).
  bool isStopBreathingSample(double value) => band.isInBand(value);

  void reset() {
    _sawInhale = false;
    _sawExhale = false;
    _validCycleCount = 0;
  }
}
