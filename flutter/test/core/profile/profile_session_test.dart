import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/data/profile_repository.dart';
import 'package:masker_app/core/profile/device_profile.dart';
import 'package:masker_app/core/profile/device_profile_service.dart';
import 'package:masker_app/core/profile/profile_session.dart';
import 'package:masker_app/core/profile/user_profile.dart';
import 'package:masker_app/core/profile/user_profile_service.dart';

class _NullProfileRepository implements ProfileRepository {
  @override
  Future<void> unbindDevice() async {}
  @override
  Future<void> unregisterUser() async {}
  @override
  Future<UserProfile?> fetchUserProfile() async => null;
  @override
  Future<DeviceProfile?> fetchDeviceProfile() async => null;
  @override
  Future<void> saveUserProfile(UserProfile profile) async {}
}

class _ThrowingFetchRepository implements ProfileRepository {
  @override
  Future<void> unbindDevice() async {}
  @override
  Future<void> unregisterUser() async {}
  @override
  Future<UserProfile?> fetchUserProfile() async => throw Exception('network');
  @override
  Future<DeviceProfile?> fetchDeviceProfile() async => throw Exception('network');
  @override
  Future<void> saveUserProfile(UserProfile profile) async {}
}

void main() {
  setUp(() {
    ProfileRepository.instance = SimulatedProfileRepository(latency: Duration.zero);
    UserProfileService.instance.reset();
    DeviceProfileService.instance.reset();
  });
  tearDown(ProfileRepository.reset);

  test('hydrate populates both stores from a returning-user repo; returns false', () async {
    ProfileRepository.instance =
        SimulatedProfileRepository.seededReturningUser(latency: Duration.zero);
    final needsOnboarding = await ProfileSession.hydrate();
    expect(needsOnboarding, isFalse);
    expect(UserProfileService.instance.current, demoUserProfile);
    expect(DeviceProfileService.instance.current, demoDeviceProfile);
  });

  test('hydrate on a new-user (default) repo leaves stores empty; returns true', () async {
    final needsOnboarding = await ProfileSession.hydrate();
    expect(needsOnboarding, isTrue);
    expect(UserProfileService.instance.current, isNull);
    expect(DeviceProfileService.instance.current, isNull);
  });

  test('hydrate clears the stores when the repository returns null', () async {
    UserProfileService.instance.set(const UserProfile(userId: 'stale'));
    DeviceProfileService.instance.set(const DeviceProfile(bindingId: 'stale'));
    ProfileRepository.instance = _NullProfileRepository();

    await ProfileSession.hydrate();

    expect(UserProfileService.instance.current, isNull);
    expect(DeviceProfileService.instance.current, isNull);
  });

  test('a fetch failure does not throw, clears the stores, and returns false (not "onboard")', () async {
    UserProfileService.instance.set(const UserProfile(userId: 'stale'));
    DeviceProfileService.instance.set(const DeviceProfile(bindingId: 'stale'));
    ProfileRepository.instance = _ThrowingFetchRepository();

    final needsOnboarding = await ProfileSession.hydrate();

    expect(needsOnboarding, isFalse);
    expect(UserProfileService.instance.current, isNull);
    expect(DeviceProfileService.instance.current, isNull);
  });
}
