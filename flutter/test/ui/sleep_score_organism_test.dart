import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/sleep_score_organism.dart';

void main() {
  testWidgets('SleepScoreOrganism renders score ring and AHI details', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SleepScoreOrganism(
            score: 92,
            ahiValue: "3.2",
            ahiStatus: "Normal",
          ),
        ),
      ),
    );

    expect(find.text("92"), findsOneWidget);
    expect(find.text("SCORE"), findsOneWidget);
    expect(find.text("AHI 3.2 (Normal)"), findsOneWidget);
    expect(find.text("NORMAL RESPIRATION"), findsOneWidget);
  });
}
