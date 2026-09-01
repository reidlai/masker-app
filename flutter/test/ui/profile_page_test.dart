import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/ui/pages/profile_page.dart';

void main() {
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
    expect(find.text("48"), findsOneWidget); // Age
    expect(find.text("85"), findsOneWidget); // Weight
    expect(find.text("178"), findsOneWidget); // Height

    // Verify Computed BMI (85 / (1.78 * 1.78) = 26.8)
    expect(find.text("26.8"), findsOneWidget);

    // Update Weight to 90kg and verify re-calculation (90 / (1.78 * 1.78) = 28.4)
    final Finder weightInput = find.widgetWithText(TextField, "85");
    await tester.enterText(weightInput, "90");
    await tester.pump();

    expect(find.text("28.4"), findsOneWidget);
  });
}
