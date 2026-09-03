import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/pages/developer_options_page.dart';

void main() {
  testWidgets('DeveloperOptionsPage renders app bar and BLE simulator organism', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeveloperOptionsPage(),
      ),
    );

    expect(find.text("Developer Options"), findsOneWidget);
    expect(find.text("Hardware & Telemetry Simulator"), findsOneWidget);
    expect(find.text("BLE Signal Simulator"), findsOneWidget);
  });
}
