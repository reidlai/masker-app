import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/profile/user_profile.dart';
import 'package:masker_app/core/profile/user_profile_service.dart';

void main() {
  setUp(UserProfileService.instance.reset);

  test('starts empty: current is null and stream replays null', () async {
    final svc = UserProfileService.instance;
    expect(svc.current, isNull);
    expect(await svc.stream.first, isNull);
  });

  test('set then clear: stream emits the profile then null', () async {
    final svc = UserProfileService.instance;
    const profile = UserProfile(userId: 'u1', fullName: 'Test Patient');

    expectLater(svc.stream, emitsInOrder([isNull, profile, isNull]));

    svc.set(profile);
    expect(svc.current, profile);
    svc.clear();
    expect(svc.current, isNull);
  });
}
