import '../profile/device_profile.dart';
import '../profile/user_profile.dart';

/// Server-side profile operations. Real HTTP is not wired yet; the default
/// [instance] is a [SimulatedProfileRepository] that delays and returns the
/// demo payloads, mirroring the fake-passkey approach. Tests substitute
/// [instance].
///
/// Per the architecture spine, `unbindDevice` maps to `POST /api/v1/devices/unbind`
/// and `unregisterUser` to the account-teardown flow.
abstract class ProfileRepository {
  /// The process-wide repository. Mutable so tests can inject a fake.
  static ProfileRepository instance = SimulatedProfileRepository();

  /// Restore the default simulated repository. For test isolation.
  static void reset() => instance = SimulatedProfileRepository();

  /// Unbind the paired D-BAND sensor server-side.
  Future<void> unbindDevice();

  /// Unregister the user account server-side.
  Future<void> unregisterUser();

  /// Load the current user profile (`null` = no account / not yet fetched).
  Future<UserProfile?> fetchUserProfile();

  /// Load the current bound device (`null` = no device bound).
  Future<DeviceProfile?> fetchDeviceProfile();

  /// Persist the edited user profile server-side.
  Future<void> saveUserProfile(UserProfile profile);
}

/// Demo identity used until a real backend is wired — the values that used to
/// be hard-coded defaults on `ProfileState`.
const UserProfile demoUserProfile = UserProfile(
  userId: 'demo-user',
  fullName: 'David Miller',
  email: 'david.miller@example.com',
  phone: '(555) 019-8234',
  age: 48,
  gender: 'Male',
  weightKg: 85,
  heightCm: 178,
  computedBmi: 26.8,
  caregiverName: 'Maria Chen',
  caregiverPhone: '(555) 019-2244',
);

/// Demo bound D-BAND sensor.
final DeviceProfile demoDeviceProfile = DeviceProfile(
  bindingId: 'demo-binding',
  deviceHardwareId: 'DBAND-0001',
  bleMacAddress: 'AA:BB:CC:DD:EE:01',
  status: 'bound',
  boundAt: DateTime(2026, 9, 1),
);

/// No-backend stand-in: resolves after a short delay. Reads return the demo
/// payloads; `unbind` / `unregister` just delay (the caller clears the stores).
class SimulatedProfileRepository implements ProfileRepository {
  final Duration latency;

  SimulatedProfileRepository({this.latency = const Duration(milliseconds: 500)});

  @override
  Future<void> unbindDevice() => Future<void>.delayed(latency);

  @override
  Future<void> unregisterUser() => Future<void>.delayed(latency);

  @override
  Future<UserProfile?> fetchUserProfile() =>
      Future<UserProfile?>.delayed(latency, () => demoUserProfile);

  @override
  Future<DeviceProfile?> fetchDeviceProfile() =>
      Future<DeviceProfile?>.delayed(latency, () => demoDeviceProfile);

  @override
  Future<void> saveUserProfile(UserProfile profile) =>
      Future<void>.delayed(latency);
}
