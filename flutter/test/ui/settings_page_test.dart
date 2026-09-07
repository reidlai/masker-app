import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/core/bloc/simulator/simulator_cubit.dart';
import 'package:masker_app/ui/pages/settings_page.dart';

void main() {
  setUp(() {
    BleSimulatorDriver().resetForTest();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    bool debuggingEnabled = false,
    bool developerEnabled = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SimulatorCubit>(
          create: (_) => SimulatorCubit(),
          child: SettingsPage(
            debuggingEnabled: debuggingEnabled,
            developerEnabled: developerEnabled,
          ),
        ),
      ),
    );
  }

  testWidgets('both flags off: Account, Preferences, and Subscription groups visible, no Developer section', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Language & Region'), findsOneWidget);
    expect(find.text('Billing & subscription'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsNothing);
    expect(find.text('Simulator'), findsNothing);
    expect(find.text('Debugging'), findsNothing);
  });

  testWidgets('debugging on: DEVELOPER header + Simulator & Debugging rows, no Developer options row', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Developer'), findsNothing);
  });

  testWidgets('developer on: DEVELOPER header + Simulator & Developer options row, no Debugging row', (tester) async {
    await pumpSettings(tester, developerEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('Debugging'), findsNothing);
  });

  testWidgets('toggling Simulator switch turns simulator on and off', (tester) async {
    await pumpSettings(tester, developerEnabled: true);

    expect(BleSimulatorDriver().isSimulatorActive, isFalse);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(BleSimulatorDriver().isSimulatorActive, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(BleSimulatorDriver().isSimulatorActive, isFalse);
  });

  testWidgets('tapping Profile pushes ProfilePage; back returns to Settings', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Medical Profile'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Medical Profile'), findsNothing);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('tapping Developer pushes DeveloperOptionsPage; back returns to Settings', (tester) async {
    await pumpSettings(tester, developerEnabled: true);

    await tester.tap(find.text('Developer'));
    await tester.pumpAndSettle();
    expect(find.text('Developer Options'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Developer Options'), findsNothing);
    expect(find.text('Developer'), findsOneWidget);
  });

  testWidgets('tapping an inert Debugging row does nothing', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true);

    await tester.tap(find.text('Debugging'));
    await tester.pumpAndSettle();

    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Medical Profile'), findsNothing);
  });

  testWidgets('both flags on: Profile + DEVELOPER with Simulator, Debugging and Developer options', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true, developerEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('Simulator'), findsOneWidget);
    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
  });

  testWidgets('navigable rows show trailing chevrons', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true, developerEnabled: true);

    expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
  });
}
