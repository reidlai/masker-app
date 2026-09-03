import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'i_ble_sensor_driver.dart';

/// Real Native Bluetooth Hardware Driver using flutter_blue_plus.
/// Communicates with physical D-BAND sensor array over BLE 5.0+ (AES-128 link security).
class FlutterBlueSensorDriver implements IBLESensorDriver {
  static final Guid serviceUuid = Guid("0000180d-0000-1000-8000-00805f9b34fb");
  static final Guid characteristicUuid = Guid("00002a37-0000-1000-8000-00805f9b34fb");

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _telemetryCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _notifySub;

  final StreamController<double> _thermalStreamController = StreamController<double>.broadcast();

  @override
  Stream<double> get thermalStream => _thermalStreamController.stream;

  final double _apneaThreshold = 0.5;
  @override
  double get apneaThreshold => _apneaThreshold;

  @override
  Future<bool> scanAndConnect() async {
    final Completer<bool> completer = Completer<bool>();

    // 1. Check Bluetooth availability
    if (await FlutterBluePlus.isSupported == false) {
      return false;
    }

    // 2. Start scanning for D-BAND BLE service
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.advertisementData.serviceUuids.contains(serviceUuid) ||
            r.device.platformName.contains("D-BAND")) {
          await FlutterBluePlus.stopScan();
          _scanSub?.cancel();

          _connectedDevice = r.device;
          // 3. Connect & Pair
          await _connectedDevice!.connect(timeout: const Duration(seconds: 5));

          // 4. Discover Services & Characteristics
          List<BluetoothService> services = await _connectedDevice!.discoverServices();
          for (BluetoothService service in services) {
            if (service.uuid == serviceUuid) {
              for (BluetoothCharacteristic characteristic in service.characteristics) {
                if (characteristic.uuid == characteristicUuid) {
                  _telemetryCharacteristic = characteristic;
                  completer.complete(true);
                  return;
                }
              }
            }
          }
        }
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => false,
    );
  }

  @override
  void startTelemetryLogging() async {
    if (_telemetryCharacteristic != null) {
      await _telemetryCharacteristic!.setNotifyValue(true);
      _notifySub = _telemetryCharacteristic!.onValueReceived.listen((value) {
        if (value.isNotEmpty) {
          // Parse raw BLE byte stream to thermal temperature delta (L/s)
          double rawThermal = value[0] + (value.length > 1 ? value[1] / 100.0 : 0.0);
          _thermalStreamController.add(rawThermal);
        }
      });
    }
  }

  @override
  void stopTelemetryLogging() async {
    _notifySub?.cancel();
    if (_telemetryCharacteristic != null) {
      await _telemetryCharacteristic!.setNotifyValue(false);
    }
  }

  @override
  void disconnect() async {
    stopTelemetryLogging();
    _scanSub?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _thermalStreamController.close();
  }
}
