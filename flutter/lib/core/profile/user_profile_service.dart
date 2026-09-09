import 'package:rxdart/rxdart.dart';
import 'user_profile.dart';

/// Process-wide reactive holder for the current [UserProfile].
///
/// Backed by a `BehaviorSubject<UserProfile?>` seeded `null` — `null` means
/// "empty" (no profile loaded). In the current slice the value is only ever
/// cleared (on Unregister / Log out); a fetch path that calls [set] is deferred.
class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  final BehaviorSubject<UserProfile?> _subject =
      BehaviorSubject<UserProfile?>.seeded(null);

  /// Latest-value replaying stream of the current profile (or `null`).
  ValueStream<UserProfile?> get stream => _subject.stream;

  /// The current profile, or `null` when empty.
  UserProfile? get current => _subject.valueOrNull;

  /// Replace the current profile.
  void set(UserProfile profile) => _subject.add(profile);

  /// Empty the store (`null`).
  void clear() => _subject.add(null);

  /// Reset to empty. For test isolation.
  void reset() => clear();
}
