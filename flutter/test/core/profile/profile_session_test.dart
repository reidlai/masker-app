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
}

void main() {
  setUp(() {
    ProfileRepository.instance = SimulatedProfileRepository(latency: Duration.zero);
    UserProfileService.instance.reset();
    DeviceProfileService.instance.reset();
  });
  tearDown(ProfileRepository.reset);

  test('hydrate populates both stores from the repository', () async {
    await ProfileSession.hydrate();
    expect(UserProfileService.instance.current, demoUserProfile);
    expect(DeviceProfileService.instance.current, demoDeviceProfile);
  });

  test('hydrate clears the stores when the repository returns null', () async {
    UserProfileService.instance.set(const UserProfile(userId: 'stale'));
    DeviceProfileService.instance.set(const DeviceProfile(bindingId: 'stale'));
    ProfileRepository.instance = _NullProfileRepository();

    await ProfileSession.hydrate();

    expect(UserProfileService.instance.current, isNull);
    expect(DeviceProfileService.instance.current, isNull);
  });

  test('a fetch failure does not throw and leaves the stores empty', () async {
    UserProfileService.instance.set(const UserProfile(userId: 'stale'));
    DeviceProfileService.instance.set(const DeviceProfile(bindingId: 'stale'));
    ProfileRepository.instance = _ThrowingFetchRepository();

    await expectLater(ProfileSession.hydrate(), completes);

    expect(UserProfileService.instance.current, isNull);
    expect(DeviceProfileService.instance.current, isNull);
  });
}
