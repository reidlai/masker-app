import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_telemetry_service.dart';
import 'package:masker_app/ui/organisms/ble_simulator_organism.dart';

void main() {
  tearDown(() {
    BleTelemetryService().resetForTest();
  });

  testWidgets('BleSimulatorOrganism renders controls and triggers callbacks', (WidgetTester tester) async {
    bool apneaTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BleSimulatorOrganism(
              onSimulateApneaAlert: () {
                apneaTriggered = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text("BLE Signal Simulator"), findsOneWidget);
    expect(find.text("1. Calibration Lifecycle Simulation"), findsOneWidget);
    expect(find.text("2. Nocturnal Sleep Cycle Simulation"), findsOneWidget);

    final apneaBtn = find.text("Simulate Apnea Stop Alert (>10s)");
    expect(apneaBtn, findsOneWidget);

    await tester.tap(apneaBtn);
    expect(apneaTriggered, isTrue);

    BleTelemetryService().resetForTest();
  });
}
