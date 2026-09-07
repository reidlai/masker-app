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
          onCalibrationComplete: (band) => completedBand = band,
        ),
      ),
    ));

    // Step 1 — idle sample.
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(kIdleSampleWindow); // sampleIdleBand future resolves
    await tester.pump();
    expect(driver.sampleIdleBandCalls, 1);
    expect(find.text('Wear check'), findsOneWidget);

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
    expect(find.text('Sensor not detecting breathing — check the fit.'),
        findsAtLeastNWidgets(1));
    expect(find.text('Retry'), findsOneWidget);
    expect(completedBand, isNull,
        reason: 'a wear-check timeout must not complete calibration');

    // Retry re-runs the wear check only — the idle sample is not repeated.
    await tester.tap(find.text('Retry'));
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
    expect(find.text('Sensor not detecting breathing — check the fit.'),
        findsAtLeastNWidgets(1));
    expect(completedBand, isNull);

    await tester.pumpWidget(const SizedBox());
    await driver.close();
  });
}
