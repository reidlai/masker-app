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

  test('instance is substitutable and reset restores the default', () {
    final fake = SimulatedProfileRepository(latency: Duration.zero);
    ProfileRepository.instance = fake;
    expect(identical(ProfileRepository.instance, fake), isTrue);

    ProfileRepository.reset();
    expect(identical(ProfileRepository.instance, fake), isFalse);
    expect(ProfileRepository.instance, isA<SimulatedProfileRepository>());
  });
}
