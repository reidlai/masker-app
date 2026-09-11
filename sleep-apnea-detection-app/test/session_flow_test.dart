// Full-tree checks for the post-login profile seed and the logout / unregister
// paths returning the app to the passkey login screen.
//
// `pumpAndSettle` is avoided once the tab shell is mounted — `MeasurementPage`
// runs periodic BLE-scan timers that never settle. Fixed pumps are used instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/onboarding/onboarding_gate.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:masker_app/core/profile/device_profile_service.dart';
import 'package:masker_app/core/profile/user_profile_service.dart';
import 'package:masker_app/main.dart';

class _GrantedPermissionService extends BlePermissionService {
  const _GrantedPermissionService();
  @override
  Future<BlePermissionStatus> checkPermission() async =>
      const BlePermissionStatus(BlePermissionResult.granted, []);
}

/// Returning user by default; `clear()` (unregister) flips it so the next
/// resolve lands on onboarding.
class _OnboardingGate implements OnboardingGate {
  bool complete = true;
  @override
  Future<bool> isComplete() async => complete;
  @override
  Future<void> markComplete() async => complete = true;
  @override
  Future<void> clear() async => complete = false;
}

Future<void> _tick(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _login(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaskerApp(permissionService: _GrantedPermissionService()),
  );
  await tester.pump(); // process AppFlowResolveRequested
  await tester.pump(const Duration(milliseconds: 50)); // land off resolving
  await tester.tap(find.text('Sign in with Passkey'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // 800ms fake auth + hydrate
  await _tick(tester);
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Settings').last);
  await _tick(tester);
}

void main() {
  setUp(() {
    // Default to a returning user so the Settings-flow tests reach the tab shell.
    ProfileRepository.instance =
        SimulatedProfileRepository.seededReturningUser(latency: Duration.zero);
    UserProfileService.instance.reset();
    DeviceProfileService.instance.reset();
    OnboardingGate.instance = _OnboardingGate();
  });
  tearDown(ProfileRepository.reset);

  testWidgets('returning-user login seeds both profile stores and lands on Home', (tester) async {
    await _login(tester);

    expect(UserProfileService.instance.current, demoUserProfile);
    expect(DeviceProfileService.instance.current, demoDeviceProfile);
    expect(find.text('12 nights monitored'), findsOneWidget); // Home is showing
  });

  testWidgets('new-user login lands on the onboarding wizard', (tester) async {
    ProfileRepository.instance = SimulatedProfileRepository(latency: Duration.zero);
    await _login(tester);

    expect(find.text('Set up your account  1/3'), findsOneWidget);
    expect(find.text('12 nights monitored'), findsNothing);
  });

  testWidgets('Log out returns to the passkey login screen', (tester) async {
    await _login(tester);
    await _openSettings(tester);

    await tester.ensureVisible(find.text('Log out'));
    await tester.tap(find.text('Log out'));
    await _tick(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log out'));
    await _tick(tester);

    expect(find.text('Sign in with Passkey'), findsOneWidget);
    expect(UserProfileService.instance.current, isNull);
    expect(DeviceProfileService.instance.current, isNull);
  });

  testWidgets('Unregister clears the gate and drops straight into onboarding',
      (tester) async {
    await _login(tester);
    await _openSettings(tester);

    await tester.ensureVisible(find.text('Unregister User Account'));
    await tester.tap(find.text('Unregister User Account'));
    await _tick(tester);
    await tester.tap(find.text('Confirm Reset'));
    await _tick(tester);

    // Onboarding flag cleared → re-resolves to the wizard, no sign-in screen.
    expect(find.text('Set up your account  1/3'), findsOneWidget);
    expect(find.text('Sign in with Passkey'), findsNothing);
    expect(UserProfileService.instance.current, isNull);
    expect(DeviceProfileService.instance.current, isNull);
  });
}
