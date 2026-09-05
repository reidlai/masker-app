import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/i_ble_sensor_driver.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:masker_app/ui/pages/measurement_page.dart';

/// Minimal [IBLESensorDriver] fake that resolves instantly, so tests never
/// depend on real BLE hardware or the simulator's timers.
class _FakeSensorDriver implements IBLESensorDriver {
  final StreamController<double> _signalController = StreamController<double>.broadcast();
  final StreamController<SensorMonitoringPhase> _phaseController =
      StreamController<SensorMonitoringPhase>.broadcast();

  bool connectCalled = false;

  @override
  Stream<double> get signalStream => _signalController.stream;

  @override
  double get signalThreshold => 0.5;

  @override
  SensorMonitoringPhase get currentPhase => SensorMonitoringPhase.idle;

  @override
  Stream<SensorMonitoringPhase> get phaseStream => _phaseController.stream;

  @override
  Future<bool> scanAndConnect() async {
    connectCalled = true;
    return true;
  }

  @override
  Future<void> startIdleCalibration() async {}

  @override
  Future<double> stopIdleCalibration() async => 0.4;

  @override
  Future<double> calibrateStage1NoiseFloor() async => 0.4;

  @override
  Future<double> calibrateStage1NoiseCeiling() async => 0.4;

  @override
  Future<void> startTrainingCalibration() async {}

  @override
  Future<double> stopTrainingCalibration() async => 0.5;

  @override
  void startMonitoringSession() {}

  @override
  void stopMonitoringSession() {}

  @override
  void disconnect() {}
}

/// Fake [BlePermissionService] whose `checkPermission()` result can be
/// swapped mid-test, so a widget test can simulate "user granted it in
/// Settings and returned to the app" without touching real permission
/// channels.
class _FakeBlePermissionService extends BlePermissionService {
  BlePermissionStatus statusToReturn;
  int checkCallCount = 0;

  _FakeBlePermissionService(this.statusToReturn);

  @override
  Future<BlePermissionStatus> checkPermission() async {
    checkCallCount++;
    return statusToReturn;
  }
}

/// Fake that throws on the first call and succeeds on the next, so a
/// "Retry" tap can be verified to actually recover.
class _ThrowsOnceBlePermissionService extends BlePermissionService {
  bool _thrown = false;

  @override
  Future<BlePermissionStatus> checkPermission() async {
    if (!_thrown) {
      _thrown = true;
      throw Exception('platform channel unavailable');
    }
    return const BlePermissionStatus(BlePermissionResult.granted, []);
  }
}

void main() {
  testWidgets('renders blocked state naming the missing permission when denied', (tester) async {
    final fakeDriver = _FakeSensorDriver();
    final fakePermissionService = _FakeBlePermissionService(
      const BlePermissionStatus(BlePermissionResult.denied, ['Bluetooth Scan', 'Bluetooth Connect']),
    );

    await tester.pumpWidget(MaterialApp(
      home: MeasurementPage(
        developerEnabled: false,
        sensorDriver: fakeDriver,
        permissionService: fakePermissionService,
      ),
    ));
    await tester.pump(); // let the async permission check resolve
    await tester.pump();

    expect(find.text("Bluetooth Permission Needed"), findsOneWidget);
    expect(find.text("Open Settings"), findsOneWidget);
    expect(find.textContaining("Bluetooth Scan"), findsOneWidget);
    // Scan never runs while blocked.
    expect(fakeDriver.connectCalled, isFalse);
  });

  testWidgets('renders blocked state naming the missing permission on a partial grant', (tester) async {
    final fakeDriver = _FakeSensorDriver();
    final fakePermissionService = _FakeBlePermissionService(
      const BlePermissionStatus(BlePermissionResult.partial, ['Bluetooth Connect']),
    );

    await tester.pumpWidget(MaterialApp(
      home: MeasurementPage(
        developerEnabled: false,
        sensorDriver: fakeDriver,
        permissionService: fakePermissionService,
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text("Bluetooth Permission Needed"), findsOneWidget);
    expect(find.textContaining("Bluetooth Connect"), findsOneWidget);
    expect(fakeDriver.connectCalled, isFalse);
  });

  testWidgets('scans normally when permission is already granted', (tester) async {
    final fakeDriver = _FakeSensorDriver();
    final fakePermissionService = _FakeBlePermissionService(
      const BlePermissionStatus(BlePermissionResult.granted, []),
    );

    await tester.pumpWidget(MaterialApp(
      home: MeasurementPage(
        developerEnabled: false,
        sensorDriver: fakeDriver,
        permissionService: fakePermissionService,
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text("Bluetooth Permission Needed"), findsNothing);
    expect(fakeDriver.connectCalled, isTrue);
  });

  testWidgets('blocked state clears on resume once permission is granted via Settings', (tester) async {
    final fakeDriver = _FakeSensorDriver();
    final fakePermissionService = _FakeBlePermissionService(
      const BlePermissionStatus(BlePermissionResult.denied, ['Bluetooth Scan', 'Bluetooth Connect']),
    );

    await tester.pumpWidget(MaterialApp(
      home: MeasurementPage(
        developerEnabled: false,
        sensorDriver: fakeDriver,
        permissionService: fakePermissionService,
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text("Bluetooth Permission Needed"), findsOneWidget);
    expect(fakeDriver.connectCalled, isFalse);

    // Simulate: user leaves for Settings, grants permission, returns.
    fakePermissionService.statusToReturn = const BlePermissionStatus(BlePermissionResult.granted, []);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(find.text("Bluetooth Permission Needed"), findsNothing);
    expect(fakeDriver.connectCalled, isTrue);
  });

  testWidgets('surfaces a retry state instead of hanging when the permission check throws', (tester) async {
    final fakeDriver = _FakeSensorDriver();

    await tester.pumpWidget(MaterialApp(
      home: MeasurementPage(
        developerEnabled: false,
        sensorDriver: fakeDriver,
        permissionService: _ThrowsOnceBlePermissionService(),
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't check Bluetooth permission"), findsOneWidget);

    await tester.tap(find.text("Retry"));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't check Bluetooth permission"), findsNothing);
    expect(fakeDriver.connectCalled, isTrue);
  });
}
