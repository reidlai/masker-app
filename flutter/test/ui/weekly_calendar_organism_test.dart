import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/weekly_calendar_organism.dart';

void main() {
  testWidgets('WeeklyCalendarOrganism renders week days and triggers selection', (WidgetTester tester) async {
    int selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyCalendarOrganism(
            onDaySelected: (idx) {
              selected = idx;
            },
          ),
        ),
      ),
    );

    expect(find.text("Weekly"), findsOneWidget);
    expect(find.text("Mo"), findsOneWidget);
    expect(find.text("Sa"), findsOneWidget);

    await tester.tap(find.text("Mo"));
    await tester.pump();
    expect(selected, equals(0));
  });
}
