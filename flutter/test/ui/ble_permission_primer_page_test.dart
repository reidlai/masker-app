import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:masker_app/ui/pages/ble_permission_primer_page.dart';

/// Fake [BlePermissionService] that resolves `requestPermission()` to a
/// fixed, injected outcome — standing in for whatever the native OS dialog(s)
/// would have resolved to (granted / denied / partial).
class _FakeBlePermissionService extends BlePermissionService {
  final BlePermissionStatus requestResult;
  bool requestCalled = false;

  _FakeBlePermissionService(this.requestResult);

  @override
  Future<BlePermissionStatus> requestPermission() async {
    requestCalled = true;
    return requestResult;
  }
}

Future<void> _pumpPrimerAndTapCta(
  WidgetTester tester,
  _FakeBlePermissionService fakeService, {
  required void Function() onPrimed,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: BlePermissionPrimerPage(
      permissionService: fakeService,
      onPrimed: onPrimed,
    ),
  ));

  expect(find.text("Allow Bluetooth Access"), findsOneWidget);
  await tester.tap(find.text("Allow Bluetooth Access"));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('CTA tap advances past the primer on full grant', (tester) async {
    bool primed = false;
    final fakeService = _FakeBlePermissionService(
      const BlePermissionStatus(BlePermissionResult.granted, []),
    );
    await _pumpPrimerAndTapCta(tester, fakeService, onPrimed: () => primed = true);

    expect(fakeService.requestCalled, isTrue);
    expect(primed, isTrue);
  });

  testWidgets('CTA tap advances past the primer on full denial', (tester) async {
    bool primed = false;
    final fakeService = _FakeBlePermissionService(
      const BlePermissionStatus(BlePermissionResult.denied, ['Bluetooth Scan', 'Bluetooth Connect']),
    );
    await _pumpPrimerAndTapCta(tester, fakeService, onPrimed: () => primed = true);

    expect(primed, isTrue);
  });

  testWidgets('CTA tap advances past the primer on partial grant', (tester) async {
    bool primed = false;
    final fakeService = _FakeBlePermissionService(
      const BlePermissionStatus(BlePermissionResult.partial, ['Bluetooth Connect']),
    );
    await _pumpPrimerAndTapCta(tester, fakeService, onPrimed: () => primed = true);

    expect(primed, isTrue);
  });

  testWidgets('primer renders a single CTA with no skip/decline control', (tester) async {
    final fakeService = _FakeBlePermissionService(
      const BlePermissionStatus(BlePermissionResult.granted, []),
    );
    await tester.pumpWidget(MaterialApp(
      home: BlePermissionPrimerPage(
        permissionService: fakeService,
        onPrimed: () {},
      ),
    ));

    expect(find.text("Allow Bluetooth Access"), findsOneWidget);
    expect(find.text("Skip"), findsNothing);
    expect(find.text("Not now"), findsNothing);
  });
}
