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
    expect(find.text("IDLE Band Sample"), findsOneWidget);
    expect(find.text("Normal 16 bpm"), findsOneWidget);
    expect(find.text("In-Band >10s"), findsOneWidget);
    expect(find.text("Recovery 5s"), findsOneWidget);
    // The retired 2-stage chip is gone.
    expect(find.text("Active Baseline"), findsNothing);

    await tester.tap(find.text("In-Band >10s"));
    await tester.pump();

    expect(BleSimulatorDriver().currentScenario, equals(SimulatorScenario.inBandNoExcursion));

    BleSimulatorDriver().resetForTest();
  });
}
