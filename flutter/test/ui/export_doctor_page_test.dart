import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/export_doctor_page.dart';

void main() {
  group('ExportDoctorPage Widget Tests', () {
    testWidgets('ExportDoctorPage renders report preview and export button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExportDoctorPage(),
        ),
      );

      // Verify title and button
      expect(find.text('Export Physician Report'), findsOneWidget);
      expect(find.text('PHYSICIAN SUMMARY REPORT'), findsOneWidget);
      expect(find.text('Export Signed PDF Report'), findsOneWidget);
    });
  });
}
