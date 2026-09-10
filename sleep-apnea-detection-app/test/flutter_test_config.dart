import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/onboarding/onboarding_gate.dart';

/// Auto-loaded by `flutter test` before every test file's `main()`.
///
/// The default [OnboardingGate] is `SharedPreferencesOnboardingGate`, whose
/// `getInstance()` throws `MissingPluginException` under `flutter test`. Swap in
/// an in-memory gate for the whole suite — default **complete** so a plain
/// `AppFlowBloc()` resolves to `loggedOut` (the pre-boot-resolve behaviour every
/// existing test assumes). Tests that need the wizard inject their own gate.
class _InMemoryOnboardingGate implements OnboardingGate {
  bool complete = true;

  @override
  Future<bool> isComplete() async => complete;
  @override
  Future<void> markComplete() async => complete = true;
  @override
  Future<void> clear() async => complete = false;
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Fresh instance before every test so a `markComplete()` / `clear()` in one
  // test can't leak into the next.
  setUp(() => OnboardingGate.instance = _InMemoryOnboardingGate());
  await testMain();
}
