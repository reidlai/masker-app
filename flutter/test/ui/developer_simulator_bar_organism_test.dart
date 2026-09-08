import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/core/bloc/simulator/simulator_bloc.dart';
import 'package:masker_app/core/bloc/simulator/simulator_event.dart';
import 'package:masker_app/ui/organisms/developer_simulator_bar_organism.dart';

void main() {
  setUp(() {
    BleSimulatorDriver().setSimulatorEnabled(true);
  });

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

  testWidgets(
      'renders nothing when the simulator is off at mount — no container, no '
      'header, no icon', (WidgetTester tester) async {
    BleSimulatorDriver().setSimulatorEnabled(false);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DeveloperSimulatorBarOrganism(),
        ),
      ),
    );

    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsNothing);
    expect(find.text("Stop Breathing during sleep"), findsNothing);
    expect(find.text("Normal Breathing during sleep"), findsNothing);
    expect(find.byIcon(Icons.tune), findsNothing);
    expect(
      find.descendant(
        of: find.byType(DeveloperSimulatorBarOrganism),
        matching: find.byType(Container),
      ),
      findsNothing,
    );
  });

  testWidgets(
      'showEvenIfInactive: true renders the bar despite the simulator being off',
      (WidgetTester tester) async {
    BleSimulatorDriver().setSimulatorEnabled(false);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DeveloperSimulatorBarOrganism(showEvenIfInactive: true),
        ),
      ),
    );

    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
  });

  testWidgets(
      'tracks a runtime toggle under a real SimulatorBloc: visible → off → '
      'hidden → on → visible again', (WidgetTester tester) async {
    BleSimulatorDriver().setSimulatorEnabled(true);
    late SimulatorBloc simBloc;

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SimulatorBloc>(
          create: (_) {
            simBloc = SimulatorBloc();
            return simBloc;
          },
          child: const Scaffold(body: DeveloperSimulatorBarOrganism()),
        ),
      ),
    );

    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsOneWidget);

    simBloc.add(const SimulatorEnabledSet(false));
    await tester.pump();
    await tester.pump();
    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsNothing);
    expect(find.byIcon(Icons.tune), findsNothing);

    simBloc.add(const SimulatorEnabledSet(true));
    await tester.pump();
    await tester.pump();
    expect(find.text("⚡ DEV SIMULATOR TOOLBAR"), findsOneWidget);

    BleSimulatorDriver().resetForTest();
    await tester.pump();
  });
}
