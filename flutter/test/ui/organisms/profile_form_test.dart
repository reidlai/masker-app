import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/profile/user_profile.dart';
import 'package:masker_app/core/profile/user_profile_service.dart';
import 'package:masker_app/ui/organisms/profile_form.dart';

class _SaveThrowsRepository extends SimulatedProfileRepository {
  _SaveThrowsRepository() : super(latency: Duration.zero);
  @override
  Future<void> saveUserProfile(UserProfile profile) async =>
      throw Exception('network');
}

const _valid = UserProfile(
  userId: 'u1',
  fullName: 'David Miller',
  email: 'david.miller@example.com',
  phone: '(555) 019-8234',
  age: 48,
  weightKg: 85,
  heightCm: 178,
  caregiverName: 'Maria Chen',
  caregiverPhone: '(555) 019-2244',
);

void main() {
  Finder fieldWithValue(String value) => find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == value,
      );

  setUp(() {
    UserProfileService.instance.reset();
    ProfileRepository.instance = SimulatedProfileRepository(latency: Duration.zero);
  });
  tearDown(ProfileRepository.reset);

  Future<GlobalKey<ProfileFormState>> pump(
    WidgetTester tester, {
    VoidCallback? onSaved,
  }) async {
    // Tall form — give it room so every field + the CTA render on-screen.
    await tester.binding.setSurfaceSize(const Size(1000, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey<ProfileFormState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ProfileForm(key: key, onSaved: onSaved)),
    ));
    return key;
  }

  testWidgets('renders the three profile organisms + primary CTA', (tester) async {
    await pump(tester);
    expect(find.text('Patient Identification (HIPAA Level 1 PHI)'), findsOneWidget);
    expect(find.text('Health Baseline Demographics'), findsOneWidget);
    expect(find.text('Tier-2 Caregiver Emergency Contact'), findsOneWidget);
    expect(find.text('Save & Continue'), findsOneWidget);
  });

  testWidgets('save() with valid values persists + shows the success snackbar', (tester) async {
    UserProfileService.instance.set(_valid);
    final key = await pump(tester);

    unawaited(key.currentState!.save());
    await tester.pumpAndSettle();

    expect(UserProfileService.instance.current!.fullName, 'David Miller');
    expect(find.text('Medical profile saved ✓'), findsOneWidget);
  });

  testWidgets('save() with invalid fields shows inline errors and does not persist', (tester) async {
    UserProfileService.instance.set(_valid);
    final key = await pump(tester);

    await tester.enterText(fieldWithValue('david.miller@example.com'), 'not-an-email');
    await tester.enterText(fieldWithValue('48'), 'x'); // age
    unawaited(key.currentState!.save());
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Enter a whole number'), findsOneWidget);
    expect(UserProfileService.instance.current!.email, 'david.miller@example.com');
  });

  testWidgets('correcting the field and re-saving clears the error and persists', (tester) async {
    UserProfileService.instance.set(_valid);
    final key = await pump(tester);

    await tester.enterText(fieldWithValue('david.miller@example.com'), 'bad');
    unawaited(key.currentState!.save());
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(fieldWithValue('bad'), 'good@example.com');
    unawaited(key.currentState!.save());
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsNothing);
    expect(UserProfileService.instance.current!.email, 'good@example.com');
  });

  testWidgets('onSaved fires once on success; the success snackbar is suppressed', (tester) async {
    UserProfileService.instance.set(_valid);
    var saved = 0;
    final key = await pump(tester, onSaved: () => saved++);

    unawaited(key.currentState!.save());
    await tester.pumpAndSettle();

    expect(saved, 1);
    expect(find.text('Medical profile saved ✓'), findsNothing);
  });

  testWidgets('a write failure shows the error snackbar and does not fire onSaved', (tester) async {
    UserProfileService.instance.set(_valid);
    ProfileRepository.instance = _SaveThrowsRepository();
    var saved = 0;
    final key = await pump(tester, onSaved: () => saved++);

    unawaited(key.currentState!.save());
    await tester.pumpAndSettle();

    expect(find.text("Couldn't save — try again."), findsOneWidget);
    expect(saved, 0);
  });

  testWidgets('a second save() while one is in flight is ignored', (tester) async {
    UserProfileService.instance.set(_valid);
    ProfileRepository.instance =
        SimulatedProfileRepository(latency: const Duration(milliseconds: 200));
    final key = await pump(tester);

    await tester.enterText(fieldWithValue('David Miller'), 'Once');
    unawaited(key.currentState!.save()); // begins (200ms)
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(fieldWithValue('Once'), 'Twice');
    unawaited(key.currentState!.save()); // ignored — first still in flight
    await tester.pumpAndSettle();

    expect(UserProfileService.instance.current!.fullName, 'Once');
  });
}
