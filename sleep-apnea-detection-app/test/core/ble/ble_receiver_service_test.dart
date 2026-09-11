import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_receiver_service.dart';
import 'package:masker_app/core/ble/mock_ble_sensor_driver.dart';
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
      expect(receiverService.reactiveStream.value, equals(0.3));
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

    test('Driver Polymorphism allows dynamic switching between MockBLESensorDriver and BleSimulatorDriver', () async {
      final hardwareDriver = MockBLESensorDriver();
      receiverService.setActiveDriver(hardwareDriver);

      expect(receiverService.activeDriver, equals(hardwareDriver));

      bool connected = await receiverService.scanAndConnect();
      expect(connected, isTrue);
      expect(hardwareDriver.state, equals(BLEDeviceState.connected));

      hardwareDriver.disconnect();
    });

    test('simulatorActiveStream mirrors BleSimulatorDriver.instance.isSimulatorStream regardless of activeDriver', () async {
      // Ancestor-independent: even bound to a non-simulator driver, the
      // getter still tracks the process-wide singleton toggle (AD spec-fix-
      // ble-real-driver-synthetic-connected-status). Collapse with distinct()
      // — scanAndConnect()/startSimulationScenario() each re-assert `true`
      // on toggle-on, an unrelated BleSimulatorDriver internal this test
      // must not couple to; only the resulting value transitions matter.
      receiverService.setActiveDriver(MockBLESensorDriver());
      BleSimulatorDriver.instance.setSimulatorEnabled(false);

      final values = <bool>[];
      final sub =
          receiverService.simulatorActiveStream.distinct().listen(values.add);
      await Future.delayed(const Duration(milliseconds: 20));

      // BehaviorSubject replays its current value on subscribe.
      expect(values, equals([false]));

      BleSimulatorDriver.instance.setSimulatorEnabled(true);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(values, equals([false, true]));

      BleSimulatorDriver.instance.setSimulatorEnabled(false);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(values, equals([false, true, false]));
      expect(BleSimulatorDriver.instance.isSimulatorStream.value, isFalse);

      await sub.cancel();
      BleSimulatorDriver.instance.resetForTest();
    });
  });
}
