import 'package:rxdart/rxdart.dart';

class BleTelemetryService {
  final BehaviorSubject<double> _signalSubject = BehaviorSubject<double>.seeded(0.0);
  final BehaviorSubject<bool> _isSimulatorSubject = BehaviorSubject<bool>.seeded(false);

  ValueStream<double> get signalStream => _signalSubject.stream;
  ValueStream<bool> get isSimulatorStream => _isSimulatorSubject.stream;

  double get latestSignal => _signalSubject.value;
  bool get isSimulatorActive => _isSimulatorSubject.value;

  void emitSignal(double value, {bool isSimulator = false}) {
    _isSimulatorSubject.add(isSimulator);
    _signalSubject.add(value);
  }

  void dispose() {
    _signalSubject.close();
    _isSimulatorSubject.close();
  }
}
