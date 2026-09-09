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
    expect(find.text('Unbind BLE Sensor Device'), findsNothing);
    expect(find.text('Unregister User Account'), findsNothing);
    expect(find.text('Inspect Circular RAM Buffer (10Hz)'), findsNothing);
    expect(find.text('Verify AES-128 BLE Link Encryption'), findsNothing);
  });

  testWidgets('debugging on: DEVELOPER section shows simulators, Debugging, reset rows & System Diagnostics; no Developer nav row', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('BLE Simulator'), findsOneWidget);
    expect(find.text('Passkey Simulator'), findsOneWidget);
    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Unbind BLE Sensor Device'), findsOneWidget);
    expect(find.text('Unregister User Account'), findsOneWidget);
    expect(find.text('Inspect Circular RAM Buffer (10Hz)'), findsOneWidget);
    expect(find.text('Verify AES-128 BLE Link Encryption'), findsOneWidget);
    expect(find.text('Developer'), findsNothing);
  });

  testWidgets('developer on: DEVELOPER section shows simulators & reset rows; no Debugging row, no Developer nav row', (tester) async {
    await pumpSettings(tester, developerEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('BLE Simulator'), findsOneWidget);
    expect(find.text('Passkey Simulator'), findsOneWidget);
    expect(find.text('Unbind BLE Sensor Device'), findsOneWidget);
    expect(find.text('Inspect Circular RAM Buffer (10Hz)'), findsOneWidget);
    expect(find.text('Developer'), findsNothing);
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

  testWidgets('tapping an inert Debugging row does nothing', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true);

    await tester.tap(find.text('Debugging'));
    await tester.pumpAndSettle();

    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Medical Profile'), findsNothing);
  });

  testWidgets('both flags on: Profile + DEVELOPER with simulators, Debugging, reset rows & System Diagnostics; no Developer nav row', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true, developerEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('BLE Simulator'), findsOneWidget);
    expect(find.text('Passkey Simulator'), findsOneWidget);
    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Unbind BLE Sensor Device'), findsOneWidget);
    expect(find.text('Unregister User Account'), findsOneWidget);
    expect(find.text('Inspect Circular RAM Buffer (10Hz)'), findsOneWidget);
    expect(find.text('Verify AES-128 BLE Link Encryption'), findsOneWidget);
    expect(find.text('Developer'), findsNothing);
  });

  testWidgets('reset rows open their confirmation dialogs and Cancel dismisses', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true);

    await tester.ensureVisible(find.text('Unbind BLE Sensor Device'));
    await tester.tap(find.text('Unbind BLE Sensor Device'));
    await tester.pumpAndSettle();
    expect(find.text('Unbind BLE Sensor?'), findsOneWidget);
    expect(find.text('Confirm Reset'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Unbind BLE Sensor?'), findsNothing);

    await tester.ensureVisible(find.text('Unregister User Account'));
    await tester.tap(find.text('Unregister User Account'));
    await tester.pumpAndSettle();
    expect(find.text('Unregister User Account?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Unregister User Account?'), findsNothing);
  });

  testWidgets('navigable rows show trailing chevrons (4 top-level nav rows; Developer rows are chevron-less)', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true, developerEnabled: true);

    expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
  });
}
