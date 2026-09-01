import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/ui/pages/summary_screen_page.dart';

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

    // Tap Export button
    await tester.tap(exportBtn);
    await tester.pump();

    // Verify SnackBar toast
    expect(find.text("Exporting Signed FHIR JSON / PDF Clinical Report..."), findsOneWidget);
  });
}
