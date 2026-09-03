import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/summary_metrics_grid_organism.dart';

void main() {
  testWidgets('SummaryMetricsGridOrganism renders metrics values', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SummaryMetricsGridOrganism(),
        ),
      ),
    );

    expect(find.text("Total Apnea Stops"), findsOneWidget);
    expect(find.text("2 Events"), findsOneWidget);
    expect(find.text("Safety Taps"), findsOneWidget);
    expect(find.text("1 Tap ('I'm Safe')"), findsOneWidget);
  });
}
