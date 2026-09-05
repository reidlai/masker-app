import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_receiver_service.dart';
import 'package:masker_app/core/ble/ble_sensor_driver.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';

void main() {
  group('BleReceiverService Unit Tests (NFR-4.6 Polymorphism & RxDart Queue)', () {
    late BleReceiverService receiverService;

    setUp(() {
      receiverService = BleReceiverService();
      receiverService.resetForTest();
    });

    tearDown(() {
      receiverService.dispose();
    });

    test('App Boot Service Launch seeds initial reactive stream value', () async {
      expect(receiverService.reactiveStream.value, equals(5.0));
      expect(receiverService.activeDriver, isA<BleSimulatorDriver>());
    });

    test('RxDart Stream Broadcast ingests telemetry values into BehaviorSubject queue', () async {
      final List<double> values = [];
      final subscription = receiverService.signalStream.listen(values.add);

      BleSimulatorDriver().emitSignal(12.5, isSimulator: true);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(values, contains(12.5));
      expect(receiverService.reactiveStream.value, equals(12.5));

      await subscription.cancel();
    });

    test('Multiple Downstream Listeners receive identical bio-signal streams concurrently', () async {
      final List<double> listener1Values = [];
      final List<double> listener2Values = [];

      final sub1 = receiverService.signalStream.listen(listener1Values.add);
      final sub2 = receiverService.signalStream.listen(listener2Values.add);

      BleSimulatorDriver().emitSignal(8.4, isSimulator: true);
      BleSimulatorDriver().emitSignal(3.2, isSimulator: true);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(listener1Values, containsAll([8.4, 3.2]));
      expect(listener2Values, containsAll([8.4, 3.2]));
      expect(listener1Values, equals(listener2Values));

      await sub1.cancel();
      await sub2.cancel();
    });

    test('Driver Polymorphism allows dynamic switching between BLESensorDriver and BleSimulatorDriver', () async {
      final hardwareDriver = BLESensorDriver();
      receiverService.setActiveDriver(hardwareDriver);

      expect(receiverService.activeDriver, equals(hardwareDriver));
      expect(receiverService.signalThreshold, equals(hardwareDriver.signalThreshold));

      bool connected = await receiverService.scanAndConnect();
      expect(connected, isTrue);
      expect(hardwareDriver.state, equals(BLEDeviceState.connected));
    });
  });
}
