import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/onboarding/onboarding_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('isComplete() is false on a fresh install', () async {
    expect(await SharedPreferencesOnboardingGate().isComplete(), isFalse);
  });

  test('markComplete() then isComplete() is true', () async {
    final gate = SharedPreferencesOnboardingGate();
    await gate.markComplete();
    expect(await gate.isComplete(), isTrue);
  });

  test('clear() forgets a completed flag', () async {
    final gate = SharedPreferencesOnboardingGate();
    await gate.markComplete();
    await gate.clear();
    expect(await gate.isComplete(), isFalse);
  });

  test('an already-set flag is read as complete', () async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    expect(await SharedPreferencesOnboardingGate().isComplete(), isTrue);
  });
}
