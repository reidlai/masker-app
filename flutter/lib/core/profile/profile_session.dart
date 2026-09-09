import '../data/profile_repository.dart';
import 'device_profile_service.dart';
import 'user_profile_service.dart';

/// Post-login bootstrap: pull the user + device profile from
/// [ProfileRepository] into the reactive stores. A `null` result clears the
/// corresponding store. Called from `main` right after passkey login, before
/// the app-flow advances to the tab shell.
class ProfileSession {
  const ProfileSession._();

  static Future<void> hydrate() async {
    await _load(
      () => ProfileRepository.instance.fetchUserProfile(),
      (p) => UserProfileService.instance.set(p),
      () => UserProfileService.instance.clear(),
    );
    await _load(
      () => ProfileRepository.instance.fetchDeviceProfile(),
      (p) => DeviceProfileService.instance.set(p),
      () => DeviceProfileService.instance.clear(),
    );
  }

  /// A fetch failure must never block login — on any error, leave the store
  /// empty and let the app flow continue.
  static Future<void> _load<T>(
    Future<T?> Function() fetch,
    void Function(T) set,
    void Function() clear,
  ) async {
    try {
      final value = await fetch();
      if (value != null) {
        set(value);
      } else {
        clear();
      }
    } catch (_) {
      clear();
    }
  }
}
