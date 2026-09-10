import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/sleep_score_organism.dart';

void main() {
  testWidgets('SleepScoreOrganism renders score ring and Apnea Index details', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SleepScoreOrganism(
            score: 92,
            apneaIndexValue: "3.2",
            apneaIndexStatus: "Normal",
          ),
        ),
      ),
    );

    expect(find.text("92"), findsOneWidget);
    expect(find.text("SCORE"), findsOneWidget);
    expect(find.text("Apnea Index 3.2 (Normal)"), findsOneWidget);
    expect(find.text("NORMAL RESPIRATION"), findsOneWidget);
    expect(find.textContaining("AHI"), findsNothing);
  });
}
