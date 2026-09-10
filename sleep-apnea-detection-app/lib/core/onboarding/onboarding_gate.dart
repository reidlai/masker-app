import 'package:shared_preferences/shared_preferences.dart';

/// The persisted "this device has completed onboarding" flag that the boot-time
/// `AppFlowStage.resolving` step reads to decide sign-in vs. onboarding.
///
/// A local approximation of "is a passkey present on this device" — a real
/// FIDO2 credential-store check is a deferred follow-on
/// (`_bmad-output/implementation-artifacts/deferred-work.md`).
///
/// Injectable through [instance] (mirrors `ProfileRepository.instance` /
/// `PasskeySimulatorConfig.instance`); tests substitute a fake.
abstract class OnboardingGate {
  static OnboardingGate instance = SharedPreferencesOnboardingGate();

  /// Restore the production `SharedPreferences`-backed gate. In tests, call
  /// `SharedPreferences.setMockInitialValues(...)` first (otherwise `isComplete`
  /// throws `MissingPluginException`).
  static void reset() => instance = SharedPreferencesOnboardingGate();

  /// Whether onboarding has been completed on this device.
  Future<bool> isComplete();

  /// Record that onboarding finished.
  Future<void> markComplete();

  /// Forget the flag (account unregister).
  Future<void> clear();
}

class SharedPreferencesOnboardingGate implements OnboardingGate {
  static const _key = 'onboarding_complete';

  @override
  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
