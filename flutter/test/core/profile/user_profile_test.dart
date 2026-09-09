import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/profile/user_profile.dart';

void main() {
  const base = UserProfile(
    userId: 'u1',
    fullName: 'David Miller',
    email: 'david@example.com',
    age: 48,
    weightKg: 85,
  );

  test('copyWith replaces only the named field', () {
    final next = base.copyWith(passkeyCredentialId: 'passkey-1');

    expect(next.passkeyCredentialId, 'passkey-1');
    expect(next.userId, 'u1');
    expect(next.fullName, 'David Miller');
    expect(next.email, 'david@example.com');
    expect(next.age, 48);
    expect(next.weightKg, 85);
  });

  test('copyWith with no args is an equal copy', () {
    expect(base.copyWith(), base);
  });

  test('passkeyCredentialId participates in equality', () {
    final a = base.copyWith(passkeyCredentialId: 'passkey-1');
    final b = base.copyWith(passkeyCredentialId: 'passkey-2');

    expect(a, isNot(b));
    expect(base.passkeyCredentialId, isEmpty); // default
  });
}
