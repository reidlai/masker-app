import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/core/bloc/simulator/simulator_bloc.dart';
import 'package:masker_app/core/config/passkey_simulator_config.dart';
import 'package:masker_app/ui/pages/settings_page.dart';

void main() {
  setUp(() {
    BleSimulatorDriver().resetForTest();
    PasskeySimulatorConfig.instance.reset();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    bool debuggingEnabled = false,
    bool developerEnabled = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SimulatorBloc>(
          create: (_) => SimulatorBloc(),
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
    expect(find.text('BLE Simulator'), findsNothing);
    expect(find.text('Passkey Simulator'), findsNothing);
    expect(find.text('Debugging'), findsNothing);
  });

  testWidgets('debugging on: DEVELOPER header + BLE Simulator & Debugging rows, no Passkey Simulator or Developer options row', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('BLE Simulator'), findsOneWidget);
    expect(find.text('Passkey Simulator'), findsNothing);
    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Developer'), findsNothing);
  });

  testWidgets('developer on: DEVELOPER header + BLE Simulator, Passkey Simulator & Developer options row, no Debugging row', (tester) async {
    await pumpSettings(tester, developerEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('BLE Simulator'), findsOneWidget);
    expect(find.text('Passkey Simulator'), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('Debugging'), findsNothing);
  });

  testWidgets('toggling BLE Simulator switch turns simulator on and off', (tester) async {
    await pumpSettings(tester, developerEnabled: true);

    expect(BleSimulatorDriver().isSimulatorActive, isFalse);

    final bleSwitch = find.byKey(const Key('ble-simulator-switch'));
    expect(find.byType(Switch), findsNWidgets(2));
    expect(bleSwitch, findsOneWidget);

    await tester.tap(bleSwitch);
    await tester.pumpAndSettle();

    expect(BleSimulatorDriver().isSimulatorActive, isTrue);

    await tester.tap(bleSwitch);
    await tester.pumpAndSettle();

    expect(BleSimulatorDriver().isSimulatorActive, isFalse);
  });

  testWidgets('Passkey Simulator switch defaults On and toggling flips PasskeySimulatorConfig', (tester) async {
    await pumpSettings(tester, developerEnabled: true);

    final passkeySwitch = find.byKey(const Key('passkey-simulator-switch'));
    expect(passkeySwitch, findsOneWidget);
    expect(tester.widget<Switch>(passkeySwitch).value, isTrue);
    expect(PasskeySimulatorConfig.instance.isEnabled, isTrue);

    await tester.tap(passkeySwitch);
    await tester.pumpAndSettle();

    expect(PasskeySimulatorConfig.instance.isEnabled, isFalse);
    expect(tester.widget<Switch>(passkeySwitch).value, isFalse);

    await tester.tap(passkeySwitch);
    await tester.pumpAndSettle();

    expect(PasskeySimulatorConfig.instance.isEnabled, isTrue);
    expect(tester.widget<Switch>(passkeySwitch).value, isTrue);
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

    await tester.ensureVisible(find.text('Developer'));
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

  testWidgets('both flags on: Profile + DEVELOPER with BLE Simulator, Passkey Simulator, Debugging and Developer options', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true, developerEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('BLE Simulator'), findsOneWidget);
    expect(find.text('Passkey Simulator'), findsOneWidget);
    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
  });

  testWidgets('navigable rows show trailing chevrons', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true, developerEnabled: true);

    expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
  });
}
