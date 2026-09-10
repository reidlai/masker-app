import '../data/profile_repository.dart';
import 'device_profile_service.dart';
import 'user_profile_service.dart';

/// Post-login bootstrap: pull the user + device profile from
/// [ProfileRepository] into the reactive stores. A `null` result clears the
/// corresponding store. Called from `main` right after passkey login, before
/// the app-flow advances to the tab shell.
class ProfileSession {
  const ProfileSession._();

  /// Loads both profiles into the stores.
  ///
  /// Returns `true` only when the user-profile fetch **succeeded and returned
  /// null** — i.e. the account is known to have no profile, so onboarding is
  /// due. A fetch *error* returns `false` (leave the returning-user path alone;
  /// a transient blip must not force a re-onboard).
  static Future<bool> hydrate() async {
    final userAbsent = await _load(
      () => ProfileRepository.instance.fetchUserProfile(),
      (p) => UserProfileService.instance.set(p),
      () => UserProfileService.instance.clear(),
    );
    await _load(
      () => ProfileRepository.instance.fetchDeviceProfile(),
      (p) => DeviceProfileService.instance.set(p),
      () => DeviceProfileService.instance.clear(),
    );
    return userAbsent;
  }

  /// A fetch failure must never block login — on any error, leave the store
  /// empty and continue. Returns `true` iff the fetch cleanly returned `null`.
  static Future<bool> _load<T>(
    Future<T?> Function() fetch,
    void Function(T) set,
    void Function() clear,
  ) async {
    try {
      final value = await fetch();
      if (value != null) {
        set(value);
        return false;
      }
      clear();
      return true;
    } catch (_) {
      clear();
      return false;
    }
  }
}
