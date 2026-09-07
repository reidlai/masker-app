import 'dart:async';
import 'drift_and_noise_floor_envelope.dart';

enum ApneaState { normal, warning, breachAlert, patientSafe, caregiverEscalated }

/// On-device apnea evaluator (AD-04). Consumes the session [IdleBand] and
/// routes stop-breathing / recovery detection through a
/// [BreathExcursionDetector]. The ≥ 100 / ≥ 50 tick structure, the Tier-1
/// alarm, the Tier-2 escalation timer and the auto-silence path are unchanged
/// — the deeper Epic 3 rework is out of scope here.
class ApneaEvaluator {
  final IdleBand idleBand;
  late final BreathExcursionDetector _detector;

  ApneaState _state = ApneaState.normal;
  ApneaState get state => _state;

  int _consecutiveStopBreathingTicks = 0; // 100ms ticks (10s = 100 ticks)
  double get inBandDuration => _consecutiveStopBreathingTicks / 10.0;
  // Ticks accrued toward the ≥50-tick (5s) auto-silence since the last reset.
  // NOT strictly consecutive: a short between-breath in-band dip does not zero
  // it — only a sustained (≥ _stopStreakBeforeRecoveryReset) stop streak does.
  int _recoveryTicks = 0;

  // A valid breath cycle briefly carries the signal *through* the band each
  // cycle; that short in-band dip is not the onset of an apnea, so it must not
  // zero the recovery counter. Only a *sustained* in-band stretch does.
  // `[ASSUMPTION]` ~1 s.
  static const int _stopStreakBeforeRecoveryReset = 10;
  Timer? _tier2EscalationTimer;
  int _countdownSeconds = 30;
  int get countdownSeconds => _countdownSeconds;

  final StreamController<ApneaState> _stateStreamController = StreamController<ApneaState>.broadcast();
  Stream<ApneaState> get stateStream => _stateStreamController.stream;

  final StreamController<int> _countdownStreamController = StreamController<int>.broadcast();
  Stream<int> get countdownStream => _countdownStreamController.stream;

  ApneaEvaluator({required this.idleBand}) {
    _detector = BreathExcursionDetector(idleBand);
  }

  void evaluateSignal(double signalValue) {
    if (!signalValue.isFinite) return;
    if (_state == ApneaState.caregiverEscalated || _state == ApneaState.patientSafe) {
      return;
    }

    final bool cycleCompletedThisTick = _detector.add(signalValue);
    // A "stop-breathing tick" = resting inside the band with no valid cycle
    // completing this tick. An out-of-band excursion or a completed cycle is
    // the patient breathing.
    final bool stopTick =
        _detector.isStopBreathingSample(signalValue) && !cycleCompletedThisTick;

    if (stopTick) {
      _consecutiveStopBreathingTicks++;

      // Only a sustained in-band stretch (not a between-breath dip) resets the
      // recovery counter.
      if (_consecutiveStopBreathingTicks >= _stopStreakBeforeRecoveryReset) {
        _recoveryTicks = 0;
      }

      // 10 seconds of continuous stop-breathing = 100 ticks @ 10Hz.
      if (_consecutiveStopBreathingTicks >= 100 && _state != ApneaState.breachAlert) {
        _triggerTier1Alarm();
      }
    } else {
      _recoveryTicks++;
      _consecutiveStopBreathingTicks = 0;

      // ~5 s of breathing (out-of-band excursions / completed cycles) since the
      // last sustained in-band stretch = 50 ticks @ 10Hz -> auto-silence.
      if (_recoveryTicks >= 50 && _state == ApneaState.breachAlert) {
        autoSilenceRecovery();
      }
    }
  }

  void _triggerTier1Alarm() {
    _state = ApneaState.breachAlert;
    _stateStreamController.add(_state);
    _countdownSeconds = 30;
    _countdownStreamController.add(_countdownSeconds);

    _tier2EscalationTimer?.cancel();
    _tier2EscalationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      _countdownStreamController.add(_countdownSeconds);

      if (_countdownSeconds <= 0) {
        _tier2EscalationTimer?.cancel();
        _state = ApneaState.caregiverEscalated;
        _stateStreamController.add(_state);
      }
    });
  }

  void acknowledgePatientSafe() {
    _tier2EscalationTimer?.cancel();
    _state = ApneaState.patientSafe;
    _stateStreamController.add(_state);
  }

  void autoSilenceRecovery() {
    _tier2EscalationTimer?.cancel();
    _state = ApneaState.patientSafe;
    _stateStreamController.add(_state);
  }

  void reset() {
    _tier2EscalationTimer?.cancel();
    _detector.reset();
    _consecutiveStopBreathingTicks = 0;
    _recoveryTicks = 0;
    _state = ApneaState.normal;
    _stateStreamController.add(_state);
  }

  void dispose() {
    _tier2EscalationTimer?.cancel();
    _stateStreamController.close();
    _countdownStreamController.close();
  }
}
