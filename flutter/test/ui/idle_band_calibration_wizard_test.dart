import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/i_ble_sensor_driver.dart';
import 'package:masker_app/core/monitoring/drift_and_noise_floor_envelope.dart';
import 'package:masker_app/ui/organisms/idle_band_calibration_wizard.dart';

/// Driver whose `signalStream` stays open and only ever emits values *inside*
/// the band its `sampleIdleBand` returns, so the wear check can never accrue a
/// strict excursion cycle — it can only ever time out.
class _InBandOnlyDriver implements IBLESensorDriver {
  final StreamController<double> _signal = StreamController<double>.broadcast();
  int sampleIdleBandCalls = 0;

  void emitInBand() => _signal.add(0.30);

  Future<void> close() => _signal.close();

  @override
  Stream<double> get signalStream => _signal.stream;

  @override
  SensorMonitoringPhase get currentPhase => SensorMonitoringPhase.idle;

  @override
  Stream<SensorMonitoringPhase> get phaseStream => const Stream.empty();

  @override
  Future<bool> scanAndConnect() async => true;

  @override
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) async {
    sampleIdleBandCalls++;
    await Future<void>.delayed(window);
    return const IdleBand(lower: 0.20, upper: 0.40);
  }

  @override
  void startMonitoringSession() {}

  @override
  void stopMonitoringSession() {}

  @override
  void disconnect() {}
}

/// `sampleIdleBand` fails immediately, so the wizard lands on its `idleError`
/// branch without waiting out the window.
class _NoSampleDriver implements IBLESensorDriver {
  final StreamController<double> _signal = StreamController<double>.broadcast();
  Future<void> close() => _signal.close();

  @override
  Stream<double> get signalStream => _signal.stream;
  @override
  SensorMonitoringPhase get currentPhase => SensorMonitoringPhase.idle;
  @override
  Stream<SensorMonitoringPhase> get phaseStream => const Stream.empty();
  @override
  Future<bool> scanAndConnect() async => true;
  @override
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) async =>
      throw StateError('no samples');
  @override
  void startMonitoringSession() {}
  @override
  void stopMonitoringSession() {}
  @override
  void disconnect() {}
}

Widget _wizardHost(IBLESensorDriver driver, {required bool isConnected}) =>
    MaterialApp(
      home: Scaffold(
        body: IdleBandCalibrationWizard(
          bleDriver: driver,
          isConnected: isConnected,
          onCalibrationComplete: (_) {},
        ),
      ),
    );

void main() {
  testWidgets(
      'wear-check timeout: <2 valid cycles holds the gate with the retry toast, '
      'and Retry re-runs the wear check (not the idle sample)', (tester) async {
    final driver = _InBandOnlyDriver();
    IdleBand? completedBand;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IdleBandCalibrationWizard(
          bleDriver: driver,
          isConnected: true,
          onCalibrationComplete: (band) => completedBand = band,
        ),
      ),
    ));

    // Step 1 — idle sample.
    await tester.tap(find.text('Start Noise Floor Sampling'));
    await tester.pump();
    await tester.pump(kIdleSampleWindow); // sampleIdleBand future resolves
    await tester.pump();
    expect(driver.sampleIdleBandCalls, 1);
    expect(find.text('Sensor Fit & Breathing Check'), findsOneWidget);

    // Tap ready button to launch Step 2 breathing check
    final readyBtn = find.text("I'm Ready — Start Breathing Check");
    expect(readyBtn, findsOneWidget);
    await tester.tap(readyBtn);
    await tester.pump();

    // Step 2 — feed only in-band samples; no strict excursion is possible.
    for (var i = 0; i < 10; i++) {
      driver.emitInBand();
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Valid breath cycles: 0 / 2'), findsOneWidget);
    expect(completedBand, isNull);

    // Window elapses -> gate held, failure copy + Retry surface.
    await tester.pump(kWearCheckWindow);
    await tester.pump();
    expect(find.text('Sensor not detecting breathing — check the fit and try again.'),
        findsAtLeastNWidgets(1));
    expect(find.text('Retry Breathing Check'), findsOneWidget);
    expect(completedBand, isNull,
        reason: 'a wear-check timeout must not complete calibration');

    // Retry re-runs the wear check only — the idle sample is not repeated.
    await tester.tap(find.text('Retry Breathing Check'));
    await tester.pump();
    expect(driver.sampleIdleBandCalls, 1,
        reason: 'Retry re-runs the wear check, not sampleIdleBand');
    expect(find.text('Valid breath cycles: 0 / 2'), findsOneWidget);

    // Still only in-band -> times out again, still gated.
    for (var i = 0; i < 5; i++) {
      driver.emitInBand();
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(kWearCheckWindow);
    await tester.pump();
    expect(find.text('Sensor not detecting breathing — check the fit and try again.'),
        findsAtLeastNWidgets(1));
    expect(completedBand, isNull);

    await tester.pumpWidget(const SizedBox());
    await driver.close();
  });

  testWidgets(
      'not connected: "Start Noise Floor Sampling" is disabled and the body '
      'copy asks the user to connect', (tester) async {
    final driver = _InBandOnlyDriver();
    addTearDown(driver.close);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IdleBandCalibrationWizard(
          bleDriver: driver,
          isConnected: false,
          onCalibrationComplete: (_) {},
        ),
      ),
    ));

    expect(find.text('Connect your D-BAND to begin noise floor sampling.'),
        findsOneWidget);
    expect(find.textContaining('Put on your D-BAND'), findsNothing);

    final startBtn = find.widgetWithText(ElevatedButton, 'Start Noise Floor Sampling');
    expect(startBtn, findsOneWidget);
    expect(tester.widget<ElevatedButton>(startBtn).onPressed, isNull);
    expect(driver.sampleIdleBandCalls, 0);

    // isConnected false -> true re-enables the button and restores the copy.
    await tester.pumpWidget(_wizardHost(driver, isConnected: true));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(startBtn).onPressed, isNotNull);
    expect(find.textContaining('Put on your D-BAND'), findsOneWidget);
    expect(find.textContaining('Connect your D-BAND'), findsNothing);
  });

  testWidgets(
      'idleError branch: "Retry" is disabled when the connection is lost',
      (tester) async {
    final driver = _NoSampleDriver();
    addTearDown(driver.close);

    // Connected → tap Start → sample fails → idleError branch shows Retry.
    await tester.pumpWidget(_wizardHost(driver, isConnected: true));
    await tester.tap(find.text('Start Noise Floor Sampling'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Retry'))
        .onPressed, isNotNull);

    // Connection lost → the same Retry button disables.
    await tester.pumpWidget(_wizardHost(driver, isConnected: false));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Retry'))
        .onPressed, isNull);
  });

  testWidgets(
      'wear-check step: "I\'m Ready" is disabled when the connection is lost',
      (tester) async {
    final driver = _InBandOnlyDriver();
    addTearDown(driver.close);

    await tester.pumpWidget(_wizardHost(driver, isConnected: true));
    await tester.tap(find.text('Start Noise Floor Sampling'));
    await tester.pump();
    await tester.pump(kIdleSampleWindow);
    await tester.pump();
    expect(find.text("I'm Ready — Start Breathing Check"), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(
            ElevatedButton, "I'm Ready — Start Breathing Check"))
        .onPressed, isNotNull);

    await tester.pumpWidget(_wizardHost(driver, isConnected: false));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(find.widgetWithText(
            ElevatedButton, "I'm Ready — Start Breathing Check"))
        .onPressed, isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'wear-check FAILED branch: "Retry Breathing Check" is disabled when the '
      'connection is lost', (tester) async {
    final driver = _InBandOnlyDriver();
    addTearDown(driver.close);

    // Connected: idle sample -> wear check -> feed only in-band -> timeout.
    await tester.pumpWidget(_wizardHost(driver, isConnected: true));
    await tester.tap(find.text('Start Noise Floor Sampling'));
    await tester.pump();
    await tester.pump(kIdleSampleWindow);
    await tester.pump();
    await tester.tap(find.text("I'm Ready — Start Breathing Check"));
    await tester.pump();
    await tester.pump(kWearCheckWindow);
    await tester.pump();
    expect(find.text('Retry Breathing Check'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Retry Breathing Check'))
        .onPressed, isNotNull);

    // Connection lost -> the same-event Retry disables like its siblings.
    await tester.pumpWidget(_wizardHost(driver, isConnected: false));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Retry Breathing Check'))
        .onPressed, isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
