import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/brand_header_organism.dart';

void main() {
  testWidgets('BrandHeaderOrganism renders title and subtitle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandHeaderOrganism(),
        ),
      ),
    );

    expect(find.text("Sleep Apnea App"), findsOneWidget);
    expect(find.text("D-BAND Integrated Respiratory Platform"), findsOneWidget);
  });
}
