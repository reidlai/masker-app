// Covers the post-login gate in `MaskerApp`/`AppFlowBloc`: whether the one-time
// Bluetooth permission primer is shown or skipped after login, based on a live
// permission status check. (The boot-time onboarding routing — which does read a
// persisted flag — is covered in app_flow_bloc_test.dart / widget_test.dart.)

import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:masker_app/main.dart';

/// Fake [BlePermissionService] returning a fixed status, so the gate's
/// branch (needsPrimer vs. ready) can be driven deterministically.
class _FakeBlePermissionService extends BlePermissionService {
  final BlePermissionStatus statusToReturn;

  const _FakeBlePermissionService(this.statusToReturn);

  @override
  Future<BlePermissionStatus> checkPermission() async => statusToReturn;
}

/// Fake that throws on the first call and succeeds on the next, so a
/// "Retry" tap can be verified to actually recover.
class _ThrowsOnceBlePermissionService extends BlePermissionService {
  bool _thrown = false;

  @override
  Future<BlePermissionStatus> checkPermission() async {
    if (!_thrown) {
      _thrown = true;
      throw Exception('platform channel unavailable');
    }
    return const BlePermissionStatus(BlePermissionResult.granted, []);
  }
}

Future<void> _loginAndSettle(WidgetTester tester) async {
  // Land off the boot-time AppFlowStage.resolving spinner first.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.text("Sign in with Passkey"));
  await tester.pump();
  // AuthBloc's default (unmocked) passkey delay is 800ms.
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    // These tests exercise the returning-user (post-onboarding) permission
    // gate. Seed a returning user; keep hydrate() instant so _loginAndSettle's
    // fixed pump budget still reaches the flow gate.
    ProfileRepository.instance =
        SimulatedProfileRepository.seededReturningUser(latency: Duration.zero);
  });
  tearDown(ProfileRepository.reset);

  testWidgets('a new user (no profile) is routed to the onboarding wizard after login', (tester) async {
    ProfileRepository.instance = SimulatedProfileRepository(latency: Duration.zero);
    await tester.pumpWidget(MaskerApp(
      permissionService: const _FakeBlePermissionService(
        BlePermissionStatus(BlePermissionResult.granted, []),
      ),
    ));

    await _loginAndSettle(tester);

    expect(find.text("Set up your account  1/3"), findsOneWidget);
    expect(find.text("Bluetooth Access Needed"), findsNothing);
  });

  testWidgets('primer is shown after login when permission is not granted', (tester) async {
    await tester.pumpWidget(MaskerApp(
      permissionService: const _FakeBlePermissionService(
        BlePermissionStatus(BlePermissionResult.denied, ['Bluetooth Scan', 'Bluetooth Connect']),
      ),
    ));

    await _loginAndSettle(tester);

    expect(find.text("Bluetooth Access Needed"), findsOneWidget);
  });

  testWidgets('primer is skipped and app goes straight to the tab shell when already granted', (tester) async {
    await tester.pumpWidget(MaskerApp(
      permissionService: const _FakeBlePermissionService(
        BlePermissionStatus(BlePermissionResult.granted, []),
      ),
    ));

    await _loginAndSettle(tester);

    expect(find.text("Bluetooth Access Needed"), findsNothing);
  });

  testWidgets('surfaces a retry state instead of hanging when the permission check throws', (tester) async {
    await tester.pumpWidget(MaskerApp(
      permissionService: _ThrowsOnceBlePermissionService(),
    ));

    await _loginAndSettle(tester);

    expect(find.text("Couldn't check Bluetooth permission"), findsOneWidget);

    await tester.tap(find.text("Retry"));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't check Bluetooth permission"), findsNothing);
  });
}
