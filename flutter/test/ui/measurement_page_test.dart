import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_sensor_driver.dart';
import 'package:masker_app/core/ble/i_ble_sensor_driver.dart';
import 'package:masker_app/core/monitoring/drift_and_noise_floor_envelope.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:masker_app/ui/pages/measurement_page.dart';

/// Minimal [IBLESensorDriver] fake that resolves instantly, so the
/// permission-gate tests never depend on real BLE hardware or timers. It is
/// NOT used to drive the calibration wizard — the end-to-end wizard case
/// below runs against a real [BLESensorDriver].
class _FakeSensorDriver implements IBLESensorDriver {
  final StreamController<double> _signalController = StreamController<double>.broadcast();
  final StreamController<SensorMonitoringPhase> _phaseController =
      StreamController<SensorMonitoringPhase>.broadcast();

  bool connectCalled = false;

  @override
  Stream<double> get signalStream => _signalController.stream;

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
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) async =>
      const IdleBand(lower: 0.25, upper: 0.35);

  @override
  void startMonitoringSession() {}

  @override
  void stopMonitoringSession() {}

  @override
  void disconnect() {}
}

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
    await tester.pump();
    await tester.pump();

    expect(find.text("Bluetooth Permission Needed"), findsOneWidget);
    expect(find.text("Open Settings"), findsOneWidget);
    expect(find.textContaining("Bluetooth Scan"), findsOneWidget);
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
    expect(find.text("Sensor Baseline & Noise Envelope Calibration"), findsOneWidget);
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

  testWidgets(
      'end-to-end: real BLESensorDriver drives the wizard through the idle '
      'sample and >=2 wear-check cycles, then Start Sleep Monitoring fires', (tester) async {
    final driver = BLESensorDriver();
    addTearDown(driver.disconnect);

    await tester.pumpWidget(MaterialApp(
      home: MeasurementPage(
        developerEnabled: false,
        sensorDriver: driver,
        permissionService: _FakeBlePermissionService(
          const BlePermissionStatus(BlePermissionResult.granted, []),
        ),
      ),
    ));

    // Permission check resolves, then scanAndConnect (~1.2 s of delays).
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text("Sensor Baseline & Noise Envelope Calibration"), findsOneWidget);
    expect(find.text("STEP 1 OF 3: NOISE FLOOR SAMPLING"), findsOneWidget);

    // Step 1 — idle sample (10 s window).
    await tester.tap(find.text("Start Noise Floor Sampling"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();

    // Step 2 — wear check. The driver's own post-sampleIdleBand emission
    // (band-spanning breathing wave) supplies the excursions; no manual
    // scenario/chip switching.
    expect(find.text("STEP 2 OF 3: WORN SAMPLING"), findsOneWidget);
    await tester.pump(const Duration(seconds: 12));
    await tester.pump();

    expect(find.text("Baseline & Fit Verified — Ready for Step 3 ✓"), findsOneWidget);

    // Start Sleep Monitoring is now enabled.
    final startButton = find.widgetWithText(ElevatedButton, "Step 3: Start Nocturnal Sleep Monitoring");
    expect(startButton, findsOneWidget);
    expect(tester.widget<ElevatedButton>(startButton).onPressed, isNotNull);

    await tester.tap(startButton);
    await tester.pump();

    expect(find.text("Night Mode Active (Battery Saver)"), findsOneWidget);
    expect(driver.currentPhase, equals(SensorMonitoringPhase.monitoring));

    // Drain the still-live monitoring emitter so no timer leaks past the test.
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('renders DeveloperSimulatorBarOrganism during active monitoring when dev mode is enabled', (tester) async {
    final driver = BLESensorDriver();
    addTearDown(driver.disconnect);

    await tester.pumpWidget(MaterialApp(
      home: MeasurementPage(
        developerEnabled: true,
        sensorDriver: driver,
        permissionService: _FakeBlePermissionService(
          const BlePermissionStatus(BlePermissionResult.granted, []),
        ),
      ),
    ));

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // In dev mode setup screen, simulator toolbar is not on setup screen.
    expect(find.text("Sensor Baseline & Noise Envelope Calibration"), findsOneWidget);

    // Complete wizard
    await tester.tap(find.text("Start Noise Floor Sampling"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();

    await tester.pump(const Duration(seconds: 12));
    await tester.pump();

    expect(find.text("Baseline & Fit Verified — Ready for Step 3 ✓"), findsOneWidget);

    final startButton = find.widgetWithText(ElevatedButton, "Step 3: Start Nocturnal Sleep Monitoring");
    await tester.tap(startButton);
    await tester.pump();

    // Dev Simulator Toolbar renders on active monitoring view during dev mode!
    expect(find.text("Night Mode Active (Battery Saver)"), findsOneWidget);
    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
  });
}
