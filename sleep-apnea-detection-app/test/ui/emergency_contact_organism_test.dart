import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/emergency_contact_organism.dart';

void main() {
  testWidgets('EmergencyContactOrganism renders title and phone input field', (WidgetTester tester) async {
    final phoneController = TextEditingController(text: '+1 555-019-2834');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EmergencyContactOrganism(
              phoneController: phoneController,
            ),
          ),
        ),
      ),
    );

    expect(find.text("Tier-2 Caregiver Emergency Contact"), findsOneWidget);
    expect(find.text("Caregiver Phone Number"), findsOneWidget);
    expect(find.text("+1 555-019-2834"), findsWidgets);
  });
}
