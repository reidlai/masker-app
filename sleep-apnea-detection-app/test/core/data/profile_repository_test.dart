import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/profile/user_profile.dart';

void main() {
  tearDown(ProfileRepository.reset);

  test('default instance is a SimulatedProfileRepository', () {
    expect(ProfileRepository.instance, isA<SimulatedProfileRepository>());
  });

  test('SimulatedProfileRepository completes both mutations without throwing',
      () async {
    final repo = SimulatedProfileRepository(latency: Duration.zero);
    await expectLater(repo.unbindDevice(), completes);
    await expectLater(repo.unregisterUser(), completes);
  });

  test('a plain SimulatedProfileRepository is empty (new user)', () async {
    final repo = SimulatedProfileRepository(latency: Duration.zero);
    expect(await repo.fetchUserProfile(), isNull);
    expect(await repo.fetchDeviceProfile(), isNull);
  });

  test('seededReturningUser returns the demo payloads', () async {
    final repo =
        SimulatedProfileRepository.seededReturningUser(latency: Duration.zero);
    expect(await repo.fetchUserProfile(), demoUserProfile);
    expect(await repo.fetchDeviceProfile(), demoDeviceProfile);
  });

  test('saveUserProfile then fetchUserProfile returns the saved profile', () async {
    final repo = SimulatedProfileRepository(latency: Duration.zero);
    const p = UserProfile(userId: 'u1', fullName: 'Saved');
    await repo.saveUserProfile(p);
    expect(await repo.fetchUserProfile(), p);
  });

  test('unregisterUser clears the stored user and device', () async {
    final repo =
        SimulatedProfileRepository.seededReturningUser(latency: Duration.zero);
    await repo.unregisterUser();
    expect(await repo.fetchUserProfile(), isNull);
    expect(await repo.fetchDeviceProfile(), isNull);
  });

  test('registerUser mints an id-only profile and stores it', () async {
    final repo = SimulatedProfileRepository(latency: Duration.zero);
    final user = await repo.registerUser();

    expect(user.userId, isNotEmpty);
    expect(user.fullName, isEmpty);
    expect(user.email, isEmpty);
    expect(user.age, 0);
    expect(await repo.fetchUserProfile(), user); // persisted
  });

  test('enrollPasskey stamps a credential id and leaves other fields intact', () async {
    final repo = SimulatedProfileRepository(latency: Duration.zero);
    final registered = await repo.registerUser();
    await repo.saveUserProfile(
      registered.copyWith(fullName: 'Dana Scully', age: 42, email: 'd@x.com'),
    );
    expect((await repo.fetchUserProfile())!.passkeyCredentialId, isEmpty);

    final enrolled = await repo.enrollPasskey();

    expect(enrolled.passkeyCredentialId, isNotEmpty);
    expect(enrolled.userId, registered.userId);
    expect(enrolled.fullName, 'Dana Scully');
    expect(enrolled.age, 42);
    expect(enrolled.email, 'd@x.com');
    expect(await repo.fetchUserProfile(), enrolled); // persisted
  });

  test('enrollPasskey throws when there is no account yet', () async {
    final repo = SimulatedProfileRepository(latency: Duration.zero);
    expect(repo.enrollPasskey(), throwsStateError);
  });

  test('instance is substitutable and reset restores the default', () {
    final fake = SimulatedProfileRepository(latency: Duration.zero);
    ProfileRepository.instance = fake;
    expect(identical(ProfileRepository.instance, fake), isTrue);

    ProfileRepository.reset();
    expect(identical(ProfileRepository.instance, fake), isFalse);
    expect(ProfileRepository.instance, isA<SimulatedProfileRepository>());
  });
}
