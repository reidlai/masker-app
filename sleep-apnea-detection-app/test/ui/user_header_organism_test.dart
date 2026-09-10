import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/user_header_organism.dart';

void main() {
  group('UserHeaderOrganism Tests', () {
    testWidgets('renders initials when avatarUrl is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserHeaderOrganism(
              firstName: 'David',
              lastName: 'Miller',
            ),
          ),
        ),
      );

      expect(find.text('Good Morning, David!'), findsOneWidget);
      expect(find.text('DM'), findsOneWidget);
    });

    testWidgets('renders single initial when lastName is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserHeaderOrganism(
              firstName: 'David',
            ),
          ),
        ),
      );

      expect(find.text('D'), findsOneWidget);
    });
  });
}
