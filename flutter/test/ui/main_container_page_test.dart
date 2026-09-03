import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/main_container_page.dart';
import 'package:masker_app/ui/pages/settings_page.dart';

void main() {
  testWidgets('tab 4 is Settings (gear icon), no Profile tab, and shows SettingsPage inline', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainContainerPage()));

    // IndexedStack mounts every tab, so MeasurementPage.initState fires a
    // simulated BLE scan (two chained 600ms delays). Drain them so no timer
    // is pending at teardown.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    final navBar = find.byType(BottomNavigationBar);
    expect(
      find.descendant(of: navBar, matching: find.text('Settings')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Profile')),
      findsNothing,
    );
    expect(
      find.descendant(of: navBar, matching: find.byIcon(Icons.settings_outlined)),
      findsOneWidget,
    );

    // Activating tab 4 brings SettingsPage onstage as the tab body.
    await tester.tap(find.descendant(of: navBar, matching: find.text('Settings')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
