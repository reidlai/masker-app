import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/report_header_organism.dart';

void main() {
  testWidgets('ReportHeaderOrganism renders title and date', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportHeaderOrganism(),
        ),
      ),
    );

    expect(find.text("Nocturnal Session Report"), findsOneWidget);
    expect(find.text("Sep 1, 2026"), findsOneWidget);
  });
}
