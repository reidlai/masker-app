import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/settings_page.dart';

void main() {
  Future<void> pumpSettings(
    WidgetTester tester, {
    bool debuggingEnabled = false,
    bool developerEnabled = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          debuggingEnabled: debuggingEnabled,
          developerEnabled: developerEnabled,
        ),
      ),
    );
  }

  testWidgets('both flags off: only the Profile row, no Advanced section', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Advanced'), findsNothing);
    expect(find.text('Debugging'), findsNothing);
    expect(find.text('Developer'), findsNothing);
  });

  testWidgets('debugging on: Advanced header + Debugging row, no Developer row', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Developer'), findsNothing);
  });

  testWidgets('developer on: Advanced header + Developer row, no Debugging row', (tester) async {
    await pumpSettings(tester, developerEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('Debugging'), findsNothing);
  });

  testWidgets('tapping Profile pushes ProfilePage; back returns to Settings', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Medical Profile'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Medical Profile'), findsNothing);
    expect(find.text('Profile'), findsOneWidget); // back on the Settings list
  });

  testWidgets('tapping an inert Advanced row does nothing', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true);

    await tester.tap(find.text('Debugging'));
    await tester.pumpAndSettle();

    // Still on Settings — no navigation occurred.
    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Medical Profile'), findsNothing);
  });

  testWidgets('both flags on: Profile + Advanced with Debugging and Developer', (tester) async {
    await pumpSettings(tester, debuggingEnabled: true, developerEnabled: true);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Debugging'), findsOneWidget);
    expect(find.text('Developer'), findsOneWidget);
  });

  testWidgets('only the navigable Profile row shows a trailing chevron', (tester) async {
    // Both inert rows present; still exactly one chevron (the Profile row).
    await pumpSettings(tester, debuggingEnabled: true, developerEnabled: true);

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
