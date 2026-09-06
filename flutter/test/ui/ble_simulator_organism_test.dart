import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/ui/organisms/ble_simulator_organism.dart';

void main() {
  tearDown(() {
    BleSimulatorDriver().resetForTest();
  });

  testWidgets('BleSimulatorOrganism renders controls and triggers callbacks', (WidgetTester tester) async {
    bool inBandTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BleSimulatorOrganism(
              onSimulateInBandNoExcursion: () {
                inBandTriggered = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text("BLE Signal Simulator"), findsOneWidget);
    expect(find.text("1. Calibration Lifecycle Simulation"), findsOneWidget);
    expect(find.text("2. Nocturnal Sleep Cycle Simulation"), findsOneWidget);

    final inBandBtn = find.text("Simulate In-Band (no excursion) >10s");
    expect(inBandBtn, findsOneWidget);

    await tester.tap(inBandBtn);
    expect(inBandTriggered, isTrue);

    BleSimulatorDriver().resetForTest();
  });
}
