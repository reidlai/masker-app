import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/organisms/ble_sensor_status_organism.dart';

void main() {
  testWidgets('BleSensorStatusOrganism renders scanning state when disconnected', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BleSensorStatusOrganism(
            isConnected: false,
          ),
        ),
      ),
    );

    expect(find.text("Scanning for D-BAND (BLE 5.0+)..."), findsOneWidget);
    expect(find.text("Service: 0x180D · AES-128 Encrypted"), findsOneWidget);
  });

  testWidgets('BleSensorStatusOrganism renders connected state when connected', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BleSensorStatusOrganism(
            isConnected: true,
          ),
        ),
      ),
    );

    expect(find.text("D-BAND Sensor Connected ✓"), findsOneWidget);
  });
}
