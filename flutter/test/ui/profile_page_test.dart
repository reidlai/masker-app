import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/profile/user_profile_service.dart';
import 'package:masker_app/ui/pages/profile_page.dart';

void main() {
  // Matches the editable value of a text field (not its hint, which is a plain Text).
  Finder fieldWithValue(String value) => find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == value,
      );

  setUp(UserProfileService.instance.reset);

  testWidgets('ProfilePage hydrates the form from the profile store and updates BMI live', (WidgetTester tester) async {
    UserProfileService.instance.set(demoUserProfile);

    await tester.pumpWidget(
      const MaterialApp(home: ProfilePage()),
    );

    expect(find.text("Medical Profile"), findsOneWidget);
    expect(find.text("David Miller"), findsWidgets); // header title + name field

    expect(fieldWithValue("David Miller"), findsOneWidget);
    expect(fieldWithValue("david.miller@example.com"), findsOneWidget);
    expect(fieldWithValue("(555) 019-8234"), findsOneWidget);
    expect(fieldWithValue("48"), findsOneWidget);
    expect(fieldWithValue("85"), findsOneWidget);
    expect(fieldWithValue("178"), findsOneWidget);
    expect(fieldWithValue("Maria Chen"), findsOneWidget);
    expect(find.text("26.8"), findsOneWidget);

    await tester.enterText(fieldWithValue("85"), "90");
    await tester.pump();
    expect(find.text("28.4"), findsOneWidget);
  });

  testWidgets('ProfilePage with an empty store shows a blank form + placeholder header', (WidgetTester tester) async {
    // store already reset to null in setUp
    await tester.pumpWidget(
      const MaterialApp(home: ProfilePage()),
    );

    expect(find.text("Complete your profile"), findsOneWidget);
    expect(fieldWithValue("David Miller"), findsNothing);
    expect(find.text("26.8"), findsNothing);
  });
}
