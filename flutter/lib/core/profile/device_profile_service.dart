import 'package:rxdart/rxdart.dart';
import 'device_profile.dart';

/// Process-wide reactive holder for the current [DeviceProfile] (the bound
/// D-BAND sensor).
///
/// Backed by a `BehaviorSubject<DeviceProfile?>` seeded `null` — `null` means
/// "empty" (no device bound). In the current slice the value is only ever
/// cleared (on Unbind / Log out); a fetch path that calls [set] is deferred.
class DeviceProfileService {
  DeviceProfileService._();

  static final DeviceProfileService instance = DeviceProfileService._();

  final BehaviorSubject<DeviceProfile?> _subject =
      BehaviorSubject<DeviceProfile?>.seeded(null);

  /// Latest-value replaying stream of the bound device (or `null`).
  ValueStream<DeviceProfile?> get stream => _subject.stream;

  /// The bound device, or `null` when empty.
  DeviceProfile? get current => _subject.valueOrNull;

  /// Replace the bound device.
  void set(DeviceProfile profile) => _subject.add(profile);

  /// Empty the store (`null`).
  void clear() => _subject.add(null);

  /// Reset to empty. For test isolation.
  void reset() => clear();
}
