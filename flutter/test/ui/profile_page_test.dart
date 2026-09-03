import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/profile_page.dart';

void main() {
  // Matches the editable value of a text field (not its hint, which is a plain Text).
  Finder fieldWithValue(String value) => find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == value,
      );

  testWidgets('ProfilePage renders David demographics and dynamically updates computed BMI', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(),
      ),
    );

    // Verify Title & User Card
    expect(find.text("Medical Profile"), findsOneWidget);
    expect(find.text("David (Persona A)"), findsOneWidget);

    // Verify Initial Demographics
    expect(fieldWithValue("48"), findsOneWidget); // Age
    expect(fieldWithValue("85"), findsOneWidget); // Weight
    expect(fieldWithValue("178"), findsOneWidget); // Height

    // Verify Computed BMI (85 / (1.78 * 1.78) = 26.8)
    expect(find.text("26.8"), findsOneWidget);

    // Update Weight to 90kg and verify re-calculation (90 / (1.78 * 1.78) = 28.4)
    await tester.enterText(fieldWithValue("85"), "90");
    await tester.pump();

    expect(find.text("28.4"), findsOneWidget);
  });
}
