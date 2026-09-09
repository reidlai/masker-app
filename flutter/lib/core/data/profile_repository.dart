/// Server-side profile operations. Real HTTP is not wired yet; the default
/// [instance] is a [SimulatedProfileRepository] that just delays and returns,
/// mirroring the fake-passkey approach. Tests substitute [instance].
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
}

/// No-backend stand-in: resolves after a short delay so callers can exercise
/// the full await → clear-store → snackbar flow.
class SimulatedProfileRepository implements ProfileRepository {
  final Duration latency;

  SimulatedProfileRepository({this.latency = const Duration(milliseconds: 500)});

  @override
  Future<void> unbindDevice() => Future<void>.delayed(latency);

  @override
  Future<void> unregisterUser() => Future<void>.delayed(latency);
}
