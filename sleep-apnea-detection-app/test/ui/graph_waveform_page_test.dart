import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/graph_waveform_page.dart';

void main() {
  group('GraphWaveformPage Widget Tests', () {
    testWidgets('GraphWaveformPage renders title and spectral analysis', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GraphWaveformPage(),
        ),
      );

      // Verify title
      expect(find.text('Respiration Waveform'), findsOneWidget);
      expect(find.text('SPECTRAL ANALYSIS & BIO-SIGNALS'), findsOneWidget);
    });
  });
}
