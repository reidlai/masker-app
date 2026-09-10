import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/health_demographics_organism.dart';

void main() {
  testWidgets('HealthDemographicsOrganism renders age, weight, height inputs and computed BMI', (WidgetTester tester) async {
    final ageController = TextEditingController(text: '48');
    final weightController = TextEditingController(text: '85');
    final heightController = TextEditingController(text: '178');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HealthDemographicsOrganism(
              ageController: ageController,
              weightController: weightController,
              heightController: heightController,
              computedBmi: 26.8,
            ),
          ),
        ),
      ),
    );

    expect(find.text("Health Baseline Demographics"), findsOneWidget);
    expect(find.text("Age (years)"), findsOneWidget);
    expect(find.text("Weight (kg)"), findsOneWidget);
    expect(find.text("Height (cm)"), findsOneWidget);
    expect(find.text("Computed BMI"), findsOneWidget);
    expect(find.text("26.8"), findsOneWidget);
  });
}
