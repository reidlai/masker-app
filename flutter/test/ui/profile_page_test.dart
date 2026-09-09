import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/profile/device_profile.dart';
import 'package:masker_app/core/profile/user_profile.dart';
import 'package:masker_app/core/profile/user_profile_service.dart';
import 'package:masker_app/ui/pages/profile_page.dart';

class _ThrowingSaveRepository implements ProfileRepository {
  @override
  Future<void> unbindDevice() async {}
  @override
  Future<void> unregisterUser() async {}
  @override
  Future<UserProfile?> fetchUserProfile() async => null;
  @override
  Future<DeviceProfile?> fetchDeviceProfile() async => null;
  @override
  Future<void> saveUserProfile(UserProfile profile) async =>
      throw Exception('network');
  @override
  Future<UserProfile> registerUser() async => throw UnimplementedError();
}

void main() {
  // Matches the editable value of a text field (not its hint, which is a plain Text).
  Finder fieldWithValue(String value) => find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == value,
      );

  setUp(() {
    UserProfileService.instance.reset();
    ProfileRepository.instance = SimulatedProfileRepository(latency: Duration.zero);
  });
  tearDown(ProfileRepository.reset);

  testWidgets('ProfilePage hydrates the form from the profile store and updates BMI live', (WidgetTester tester) async {
    UserProfileService.instance.set(demoUserProfile);

    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    expect(find.text("Medical Profile"), findsOneWidget);
    expect(find.text("David Miller"), findsWidgets); // header title + name field

    expect(fieldWithValue("David Miller"), findsOneWidget);
    expect(fieldWithValue("david.miller@example.com"), findsOneWidget);
    expect(fieldWithValue("(555) 019-8234"), findsOneWidget);
    expect(fieldWithValue("48"), findsOneWidget);
    expect(fieldWithValue("85"), findsOneWidget);
    expect(fieldWithValue("178"), findsOneWidget);
    expect(fieldWithValue("Maria Chen"), findsOneWidget);
    expect(find.text("26.8"), findsOneWidget);

    await tester.enterText(fieldWithValue("85"), "90");
    await tester.pump();
    expect(find.text("28.4"), findsOneWidget);
  });

  testWidgets('ProfilePage with an empty store shows a blank form + placeholder header', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    expect(find.text("Complete your profile"), findsOneWidget);
    expect(fieldWithValue("David Miller"), findsNothing);
    expect(find.text("26.8"), findsNothing);
  });

  testWidgets('tapping the AppBar tick persists the edited name to the store + updates the header', (tester) async {
    UserProfileService.instance.set(demoUserProfile);
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    await tester.enterText(fieldWithValue("David Miller"), "Den Miller");
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(UserProfileService.instance.current?.fullName, "Den Miller");
    expect(find.text("Medical profile saved ✓"), findsOneWidget);
    expect(find.text("Den Miller"), findsWidgets); // header retitled
  });

  testWidgets('"Save & Continue" runs the same save as the tick', (tester) async {
    UserProfileService.instance.set(demoUserProfile);
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    await tester.enterText(fieldWithValue("48"), "49");
    await tester.ensureVisible(find.text("Save & Continue"));
    await tester.tap(find.text("Save & Continue"));
    await tester.pumpAndSettle();

    expect(UserProfileService.instance.current?.age, 49);
    expect(find.text("Medical profile saved ✓"), findsOneWidget);
  });

  testWidgets('reopening ProfilePage shows the saved values', (tester) async {
    UserProfileService.instance.set(demoUserProfile);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldWithValue("David Miller"), "Saved Name");
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(fieldWithValue("Saved Name"), findsOneWidget);
  });

  testWidgets('save from an empty store: userId defaults, non-numeric age → 0', (tester) async {
    // store null (setUp reset)
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    // Form field order: name, email, phone, age, weight, height, caregiver...
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), "New Patient");
    await tester.enterText(fields.at(3), "abc"); // non-numeric age
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final saved = UserProfileService.instance.current;
    expect(saved, isNotNull);
    expect(saved!.userId, "demo-user");
    expect(saved.fullName, "New Patient");
    expect(saved.age, 0);
  });

  testWidgets('a second tap while a save is in flight is ignored', (tester) async {
    UserProfileService.instance.set(demoUserProfile);
    ProfileRepository.instance =
        SimulatedProfileRepository(latency: const Duration(milliseconds: 200));
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    await tester.enterText(fieldWithValue("David Miller"), "Once");
    await tester.tap(find.byIcon(Icons.check)); // save 1 begins (200ms)
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(fieldWithValue("Once"), "Twice");
    await tester.tap(find.byIcon(Icons.check)); // ignored — save 1 still in flight
    await tester.pumpAndSettle();

    expect(UserProfileService.instance.current?.fullName, "Once");
  });

  testWidgets('a save-write failure shows an error snackbar (store keeps the optimistic value)', (tester) async {
    UserProfileService.instance.set(demoUserProfile);
    ProfileRepository.instance = _ThrowingSaveRepository();
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    await tester.enterText(fieldWithValue("David Miller"), "Doomed Save");
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't save — try again."), findsOneWidget);
    expect(find.text("Medical profile saved ✓"), findsNothing);
    expect(UserProfileService.instance.current?.fullName, "Doomed Save");
  });
}
