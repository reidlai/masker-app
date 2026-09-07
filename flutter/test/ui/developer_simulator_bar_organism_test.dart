import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/ui/organisms/developer_simulator_bar_organism.dart';

void main() {
  tearDown(() {
    BleSimulatorDriver().resetForTest();
  });

  testWidgets('DeveloperSimulatorBarOrganism renders the IDLE Band scenario chips', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeveloperSimulatorBarOrganism(),
        ),
      ),
    );

    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsOneWidget);
    expect(find.text("Stop Breathing during sleep"), findsOneWidget);
    expect(find.text("Normal Breathing during sleep"), findsOneWidget);

    await tester.tap(find.text("Stop Breathing during sleep"));
    await tester.pump();

    expect(BleSimulatorDriver().currentScenario, equals(SimulatorScenario.inBandNoExcursion));

    BleSimulatorDriver().resetForTest();
  });
}
