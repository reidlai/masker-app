import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_sensor_driver.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/core/ble/i_ble_sensor_driver.dart';
import 'package:masker_app/core/bloc/simulator/simulator_bloc.dart';
import 'package:masker_app/core/bloc/simulator/simulator_event.dart';
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

    // Step 2 — tap ready button for wear check
    expect(find.text("STEP 2 OF 3: WORN SAMPLING"), findsOneWidget);
    await tester.tap(find.text("I'm Ready — Start Breathing Check"));
    await tester.pump();
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

    // The page-scoped bloc no longer disconnects its injected driver on close
    // (AD-12: in production that driver is the app-lifetime BleReceiverService),
    // so this test owns the teardown of the driver it constructed.
    driver.disconnect();
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

    await tester.tap(find.text("I'm Ready — Start Breathing Check"));
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

    // The page-scoped bloc no longer disconnects its injected driver on close
    // (AD-12), so this test owns the teardown of the driver it constructed.
    driver.disconnect();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
      'toggling the SimulatorBloc drives the BLE status card and keeps the dev '
      'toolbar off the setup screen', (tester) async {
    BleSimulatorDriver().resetForTest();
    addTearDown(() => BleSimulatorDriver().resetForTest());

    final fake = _ToggleableFakeDriver()..connectResult = false;
    addTearDown(fake.dispose);
    late SimulatorBloc simBloc;

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<SimulatorBloc>(
        create: (_) {
          simBloc = SimulatorBloc();
          return simBloc;
        },
        child: MeasurementPage(
          sensorDriver: fake,
          permissionService: _FakeBlePermissionService(
            const BlePermissionStatus(BlePermissionResult.granted, []),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();

    // Simulator off, real connect failed (no hardware): "Scanning…".
    expect(find.text("Scanning for D-BAND (BLE 5.0+)..."), findsOneWidget);
    expect(find.text("D-BAND Sensor Connected ✓"), findsNothing);
    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsNothing);

    // Enable the simulator → dev bypass re-runs the connect flow.
    fake.connectResult = true;
    simBloc.add(const SimulatorEnabledSet(true));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text("D-BAND Sensor Connected ✓"), findsOneWidget);
    expect(find.text("Scanning for D-BAND (BLE 5.0+)..."), findsNothing);
    // Toolbar is developer-only AND monitoring-only — never on setup.
    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsNothing);

    // Disable the simulator → real gate re-runs, connect fails again.
    fake.connectResult = false;
    simBloc.add(const SimulatorEnabledSet(false));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text("Scanning for D-BAND (BLE 5.0+)..."), findsOneWidget);
    expect(find.text("D-BAND Sensor Connected ✓"), findsNothing);
  });

  testWidgets(
      'on the monitoring screen the dev toolbar + stage panel are gated live on '
      'SimulatorBloc: toggling it off hides them without ending the session',
      (tester) async {
    BleSimulatorDriver().resetForTest();
    addTearDown(() => BleSimulatorDriver().resetForTest());
    // Simulator ON before the page mounts -> _isDevMode true at initState, and
    // the reactive context.select<SimulatorBloc> gate is the live path (no
    // developerEnabled override).
    BleSimulatorDriver().setSimulatorEnabled(true);

    final driver = BLESensorDriver();
    addTearDown(driver.disconnect);
    late SimulatorBloc simBloc;

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<SimulatorBloc>(
        create: (_) {
          simBloc = SimulatorBloc();
          return simBloc;
        },
        child: MeasurementPage(
          sensorDriver: driver,
          permissionService: _FakeBlePermissionService(
            const BlePermissionStatus(BlePermissionResult.granted, []),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Drive the wizard to an active session.
    await tester.tap(find.text("Start Noise Floor Sampling"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    await tester.tap(find.text("I'm Ready — Start Breathing Check"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 12));
    await tester.pump();
    await tester.tap(
        find.widgetWithText(ElevatedButton, "Step 3: Start Nocturnal Sleep Monitoring"));
    await tester.pump();

    expect(find.text("Night Mode Active (Battery Saver)"), findsOneWidget);
    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsOneWidget);
    expect(find.text("📊 DETECTION MECHANISM STAGE MONITOR"), findsOneWidget);

    // Toggle the simulator off mid-session.
    simBloc.add(const SimulatorEnabledSet(false));
    await tester.pump();
    await tester.pump();

    // Dev widgets gone; session still on the night-mode screen.
    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsNothing);
    expect(find.text("📊 DETECTION MECHANISM STAGE MONITOR"), findsNothing);
    expect(find.text("Night Mode Active (Battery Saver)"), findsOneWidget);

    driver.disconnect();
    await tester.pump(const Duration(milliseconds: 300));
  });
}

/// Stays the injected driver for the whole test — the `SimulatorBloc` here has
/// no `receiver`, so `setActiveDriver` is a no-op. `connectResult` is flipped by
/// hand to stand in for what a real simulator↔hardware swap would change; the
/// test exercises the page's dev-mode / connect-flow re-run, not an actual swap.
class _ToggleableFakeDriver implements IBLESensorDriver {
  final StreamController<double> _signal = StreamController<double>.broadcast();
  bool connectResult = true;

  void dispose() => _signal.close();

  @override
  Stream<double> get signalStream => _signal.stream;
  @override
  SensorMonitoringPhase get currentPhase => SensorMonitoringPhase.idle;
  @override
  Stream<SensorMonitoringPhase> get phaseStream => const Stream.empty();
  @override
  Future<bool> scanAndConnect() async => connectResult;
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
