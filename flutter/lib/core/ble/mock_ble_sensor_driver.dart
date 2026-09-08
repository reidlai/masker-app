import 'dart:async';
import 'dart:math';
import '../monitoring/drift_and_noise_floor_envelope.dart';
import 'i_ble_sensor_driver.dart';

enum BLEDeviceState { disconnected, scanning, connecting, connected }

/// Shape of the continuous synthetic emitter. `scanAndConnect` starts it in
/// [resting]; `sampleIdleBand` learns the band from [resting] then re-shapes
/// to [breathing] before returning so the wear check sees strict excursions.
enum _EmitShape { resting, breathing }

/// Pure synthetic mock driver for fast unit testing.
class MockBLESensorDriver implements IBLESensorDriver {
  static const String serviceUuid = "0x180D";
  static const String characteristicUuid = "0x2A37";

  BLEDeviceState _state = BLEDeviceState.disconnected;
  BLEDeviceState get state => _state;

  SensorMonitoringPhase _currentPhase = SensorMonitoringPhase.disconnected;
  @override
  SensorMonitoringPhase get currentPhase => _currentPhase;

  StreamController<SensorMonitoringPhase>? _phaseStreamController;
  @override
  Stream<SensorMonitoringPhase> get phaseStream {
    _phaseStreamController ??= StreamController<SensorMonitoringPhase>.broadcast();
    return _phaseStreamController!.stream;
  }

  void _updatePhase(SensorMonitoringPhase newPhase) {
    _currentPhase = newPhase;
    _phaseStreamController?.add(newPhase);
  }

  StreamController<double>? _signalStreamController;
  @override
  Stream<double> get signalStream {
    _signalStreamController ??= StreamController<double>.broadcast();
    return _signalStreamController!.stream;
  }

  // --- Continuous ~10 Hz synthetic emitter (AD-12) ---
  // Started on scanAndConnect, stopped only on disconnect. sampleIdleBand and
  // startMonitoringSession re-shape it; they never start/stop it.
  Timer? _emitTimer;
  double _step = 0.0;
  _EmitShape _shape = _EmitShape.resting;

  void _startEmitter() {
    _emitTimer?.cancel();
    _step = 0.0;
    _emitTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _step += 0.1;
      final double signal;
      switch (_shape) {
        case _EmitShape.resting:
          // Narrow resting signal around ~0.30 (tiny jitter only).
          signal = 0.30 + 0.02 * sin(_step * 3);
          break;
        case _EmitShape.breathing:
          // Band-spanning breathing wave: 0.30 ± 0.25 strictly overshoots a
          // band learned from the resting shape (~[0.28, 0.32]) on both sides.
          signal = 0.30 + 0.25 * sin(_step * 1.6);
          break;
      }
      _signalStreamController?.add(signal);
    });
  }

  @override
  Future<bool> scanAndConnect() async {
    _state = BLEDeviceState.scanning;
    await Future.delayed(const Duration(milliseconds: 600));
    _state = BLEDeviceState.connecting;
    await Future.delayed(const Duration(milliseconds: 600));
    _state = BLEDeviceState.connected;
    _updatePhase(SensorMonitoringPhase.idle);
    _shape = _EmitShape.resting;
    _startEmitter();
    return true;
  }

  @override
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) async {
    _updatePhase(SensorMonitoringPhase.calibratingIdleBand);
    _shape = _EmitShape.resting;

    final acc = IdleBandAccumulator();
    final sub = signalStream.listen(acc.add);
    await Future.delayed(window);
    unawaited(sub.cancel());

    final band = acc.band;
    if (band == null) {
      _updatePhase(SensorMonitoringPhase.idle);
      throw StateError(
        'sampleIdleBand: no samples arrived on signalStream within $window',
      );
    }

    // Re-shape the still-live emitter to the band-spanning breathing wave so
    // wizard step 2 observes strict excursions against the returned band. The
    // band is frozen at window close; widening the emission now does not
    // change it.
    _shape = _EmitShape.breathing;
    _updatePhase(SensorMonitoringPhase.idle);
    return band;
  }

  @override
  void startMonitoringSession() {
    _updatePhase(SensorMonitoringPhase.monitoring);
    _shape = _EmitShape.breathing;
    if (_emitTimer == null) _startEmitter();
  }

  @override
  void stopMonitoringSession() {
    // AD-12: the emitter runs until disconnect(); only re-shape it to resting.
    _shape = _EmitShape.resting;
    _updatePhase(SensorMonitoringPhase.idle);
  }

  @override
  void disconnect() {
    _emitTimer?.cancel();
    _emitTimer = null;
    _signalStreamController?.close();
    _signalStreamController = null;
    _state = BLEDeviceState.disconnected;
    _updatePhase(SensorMonitoringPhase.disconnected);
    _phaseStreamController?.close();
    _phaseStreamController = null;
  }
}
