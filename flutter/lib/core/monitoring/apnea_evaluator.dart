import 'dart:async';

enum ApneaState { normal, warning, breachAlert, patientSafe, caregiverEscalated }

class ApneaEvaluator {
  final double threshold;
  ApneaState _state = ApneaState.normal;
  ApneaState get state => _state;

  int _consecutiveBelowThresholdCount = 0; // 100ms ticks (10s = 100 ticks)
  int _consecutiveNormalCount = 0;         // 100ms ticks (5s = 50 ticks)
  Timer? _tier2EscalationTimer;
  int _countdownSeconds = 30;
  int get countdownSeconds => _countdownSeconds;

  final StreamController<ApneaState> _stateStreamController = StreamController<ApneaState>.broadcast();
  Stream<ApneaState> get stateStream => _stateStreamController.stream;

  final StreamController<int> _countdownStreamController = StreamController<int>.broadcast();
  Stream<int> get countdownStream => _countdownStreamController.stream;

  ApneaEvaluator({required this.threshold});

  void evaluateSignal(double signalValue) {
    if (_state == ApneaState.caregiverEscalated || _state == ApneaState.patientSafe) {
      return;
    }

    if (signalValue <= threshold) {
      _consecutiveBelowThresholdCount++;
      _consecutiveNormalCount = 0;

      // 10 seconds continuous drop = 100 ticks @ 10Hz
      if (_consecutiveBelowThresholdCount >= 100 && _state != ApneaState.breachAlert) {
        _triggerTier1Alarm();
      }
    } else {
      _consecutiveNormalCount++;
      _consecutiveBelowThresholdCount = 0;

      // 5 seconds continuous normal breathing = 50 ticks @ 10Hz -> Auto-silence
      if (_consecutiveNormalCount >= 50 && _state == ApneaState.breachAlert) {
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
    _consecutiveBelowThresholdCount = 0;
    _consecutiveNormalCount = 0;
    _state = ApneaState.normal;
    _stateStreamController.add(_state);
  }

  void dispose() {
    _tier2EscalationTimer?.cancel();
    _stateStreamController.close();
    _countdownStreamController.close();
  }
}
