import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/health_insights_organism.dart';

void main() {
  testWidgets('HealthInsightsOrganism renders article titles', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HealthInsightsOrganism(),
        ),
      ),
    );

    expect(find.text("Health & Mask Insights"), findsOneWidget);
    expect(find.text("Mask Use & Health"), findsOneWidget);
    expect(find.text("Understanding SpO2"), findsOneWidget);
  });
}
