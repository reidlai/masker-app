import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/molecules/settings_menu_row.dart';
import 'package:masker_app/ui/organisms/settings_group_card_organism.dart';

void main() {
  testWidgets('SettingsGroupCardOrganism renders children rows and optional section header', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsGroupCardOrganism(
            sectionHeader: "System",
            children: [
              SettingsMenuRow(
                leadingIcon: Icons.person_outline,
                label: "Account",
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("System"), findsOneWidget);
    expect(find.text("Account"), findsOneWidget);
  });
}
