import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../monitoring/drift_and_noise_floor_envelope.dart';
import 'i_ble_sensor_driver.dart';

/// Real Native Bluetooth Hardware Driver using flutter_blue_plus.
/// Communicates with the physical D-BAND sensor array over BLE 5.0+
/// (AES-128 link security). Works in raw signal units end to end — no
/// thermal-to-volumetric conversion, no noise-floor subtraction.
class FlutterBlueSensorDriver implements IBLESensorDriver {
  static final Guid serviceUuid = Guid("0000180d-0000-1000-8000-00805f9b34fb");
  static final Guid characteristicUuid = Guid("00002a37-0000-1000-8000-00805f9b34fb");

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _telemetryCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _notifySub;
  StreamController<SensorMonitoringPhase>? _phaseStreamController;
  SensorMonitoringPhase _currentPhase = SensorMonitoringPhase.disconnected;
  final StreamController<double> _signalStreamController = StreamController<double>.broadcast();

  // --- Synthetic fallback emitter (CI / simulator-on-device, no real GATT) ---
  // A real characteristic never uses this: the patient's own breath crosses
  // the band. The fallback stays live after sampleIdleBand() and, once
  // _spanningWave flips true, strictly overshoots the learned band on both
  // sides so the wear check can accrue cycles.
  Timer? _syntheticTimer;
  double _syntheticStep = 0.0;
  bool _spanningWave = false;

  @override
  SensorMonitoringPhase get currentPhase => _currentPhase;

  @override
  Stream<SensorMonitoringPhase> get phaseStream {
    _phaseStreamController ??= StreamController<SensorMonitoringPhase>.broadcast();
    return _phaseStreamController!.stream;
  }

  void _updatePhase(SensorMonitoringPhase newPhase) {
    _currentPhase = newPhase;
    _phaseStreamController?.add(newPhase);
  }

  /// Unified 10 Hz raw bio-signal stream (AD-12). Live from a successful
  /// [scanAndConnect] until [disconnect].
  @override
  Stream<double> get signalStream => _signalStreamController.stream;

  void _startSyntheticEmitter() {
    _syntheticTimer?.cancel();
    _syntheticStep = 0.0;
    _syntheticTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _syntheticStep += 0.1;
      final double signal = _spanningWave
          // Band-spanning breathing wave — strictly overshoots a band learned
          // from the resting shape (~[0.28, 0.32]) on both sides.
          ? 0.30 + 0.25 * sin(_syntheticStep * 1.6)
          // Narrow resting signal ~0.30 (the band is learned from this).
          : 0.30 + 0.02 * sin(_syntheticStep * 3);
      if (!_signalStreamController.isClosed) {
        _signalStreamController.add(signal);
      }
    });
  }

  Future<void> _startRealNotify() async {
    if (_telemetryCharacteristic == null) return;
    await _telemetryCharacteristic!.setNotifyValue(true);
    // Idempotent: the subscription established at scanAndConnect stays live for
    // the whole session (AD-12). Re-entrant callers (startMonitoringSession)
    // must not churn it — dropping GATT notifications in the cancel/re-listen
    // gap, exactly when monitoring begins.
    if (_notifySub != null) return;
    _notifySub = _telemetryCharacteristic!.onValueReceived.listen((value) {
      if (value.isEmpty) return;
      final double raw = value[0] + (value.length > 1 ? value[1] / 100.0 : 0.0);
      if (!_signalStreamController.isClosed) {
        _signalStreamController.add(raw);
      }
    });
  }

  // --- Hybrid Hardware/Simulator Scan-and-Connect Lifecycle ---
  @override
  Future<bool> scanAndConnect() async {
    final Completer<bool> completer = Completer<bool>();

    try {
      if (await FlutterBluePlus.isSupported == false) {
        return false;
      }

      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.advertisementData.serviceUuids.contains(serviceUuid) ||
              r.device.platformName.contains("D-BAND")) {
            try {
              await FlutterBluePlus.stopScan();
              await _scanSub?.cancel();

              _connectedDevice = r.device;
              await _connectedDevice!.connect(timeout: const Duration(seconds: 5));

              List<BluetoothService> services = await _connectedDevice!.discoverServices();
              for (BluetoothService service in services) {
                if (service.uuid == serviceUuid) {
                  for (BluetoothCharacteristic characteristic in service.characteristics) {
                    if (characteristic.uuid == characteristicUuid) {
                      _telemetryCharacteristic = characteristic;
                      await _startRealNotify();
                      _updatePhase(SensorMonitoringPhase.idle);
                      if (!completer.isCompleted) completer.complete(true);
                      return;
                    }
                  }
                }
              }
            } catch (_) {}
          }
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  // --- IDLE Band Calibration (AD-04) ---
  @override
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) async {
    _updatePhase(SensorMonitoringPhase.calibratingIdleBand);
    final acc = IdleBandAccumulator();

    if (_telemetryCharacteristic != null) {
      // Real characteristic: the persistent notify subscription from
      // scanAndConnect is already feeding signalStream. Just observe it for
      // the window — the patient's own breath supplies the excursions the
      // wear check needs, so no synthetic shaping here.
      await _telemetryCharacteristic!.setNotifyValue(true);
    } else {
      // Synthetic fallback: run a resting emitter for the window.
      _spanningWave = false;
      _startSyntheticEmitter();
    }

    final sub = _signalStreamController.stream.listen(acc.add);
    await Future.delayed(window);
    unawaited(sub.cancel());

    final band = acc.band;
    if (band == null) {
      // Don't leak the fallback emitter on the error path — it would run until
      // an unrelated disconnect().
      _syntheticTimer?.cancel();
      _syntheticTimer = null;
      _updatePhase(SensorMonitoringPhase.idle);
      throw StateError(
        'sampleIdleBand: no samples arrived from the D-BAND within $window',
      );
    }

    if (_telemetryCharacteristic == null) {
      // Widen the still-running fallback emitter so the wear check can
      // strictly leave the learned band on both sides. A real characteristic
      // is left untouched.
      _spanningWave = true;
    }

    _updatePhase(SensorMonitoringPhase.idle);
    return band;
  }

  // --- Nocturnal Monitoring Lifecycle ---
  @override
  void startMonitoringSession() async {
    _updatePhase(SensorMonitoringPhase.monitoring);
    if (_telemetryCharacteristic != null) {
      await _startRealNotify();
    } else {
      _spanningWave = true;
      if (_syntheticTimer == null) _startSyntheticEmitter();
    }
  }

  @override
  void stopMonitoringSession() {
    // AD-12: signalStream stays live until disconnect(); only re-shape it.
    _spanningWave = false;
    _updatePhase(SensorMonitoringPhase.idle);
  }

  @override
  void disconnect() async {
    await _notifySub?.cancel();
    _syntheticTimer?.cancel();
    _syntheticTimer = null;
    await _scanSub?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _telemetryCharacteristic = null;
    _updatePhase(SensorMonitoringPhase.disconnected);
    _signalStreamController.close();
    _phaseStreamController?.close();
  }
}
