import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/data/profile_repository.dart';

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

  test('SimulatedProfileRepository fetch* returns the demo payloads', () async {
    final repo = SimulatedProfileRepository(latency: Duration.zero);
    expect(await repo.fetchUserProfile(), demoUserProfile);
    expect(await repo.fetchDeviceProfile(), demoDeviceProfile);
  });

  test('SimulatedProfileRepository.saveUserProfile completes', () async {
    final repo = SimulatedProfileRepository(latency: Duration.zero);
    await expectLater(repo.saveUserProfile(demoUserProfile), completes);
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
