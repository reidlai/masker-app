import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/summary_screen_page.dart';

void main() {
  testWidgets('SummaryScreenPage renders AHI score 92, metrics grid, and FHIR export button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SummaryScreenPage(),
      ),
    );

    // Verify Title & Date Header
    expect(find.text("Morning Sleep Summary"), findsOneWidget);
    expect(find.text("Nocturnal Session Report"), findsOneWidget);

    // Verify Score & AHI Badge
    expect(find.text("92"), findsOneWidget);
    expect(find.text("AHI 3.2 (Normal)"), findsOneWidget);
    expect(find.text("NORMAL RESPIRATION"), findsOneWidget);

    // Verify Metrics Grid
    expect(find.text("2 Events"), findsOneWidget);
    expect(find.text("1 Tap ('I'm Safe')"), findsOneWidget);

    // Verify Export Button
    final Finder exportBtn = find.text("Export Signed Report for Physician");
    expect(exportBtn, findsOneWidget);

    // Button sits below the fold in the scroll view; bring it on-screen first.
    await tester.ensureVisible(exportBtn);
    await tester.pumpAndSettle();

    // Tap Export button pushes ExportDoctorPage
    await tester.tap(exportBtn);
    await tester.pumpAndSettle();

    expect(find.text("Export Physician Report"), findsOneWidget);
  });

  testWidgets('SummaryScreenPage renders back button when pushed as sub-route and pops on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SummaryScreenPage(),
                  ),
                );
              },
              child: const Text('Open Summary'),
            ),
          ),
        ),
      ),
    );

    // Tap to push SummaryScreenPage onto stack
    await tester.tap(find.text('Open Summary'));
    await tester.pumpAndSettle();

    // Verify leading back button icon is visible
    final backIcon = find.byIcon(Icons.arrow_back_ios_new);
    expect(backIcon, findsOneWidget);

    // Tap back button and verify pop back
    await tester.tap(backIcon);
    await tester.pumpAndSettle();

    expect(find.text('Open Summary'), findsOneWidget);
  });
}
