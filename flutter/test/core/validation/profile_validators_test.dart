import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/validation/profile_validators.dart';

void main() {
  group('requiredError', () {
    test('empty / whitespace → message', () {
      expect(requiredError(''), isNotNull);
      expect(requiredError('   '), isNotNull);
    });
    test('non-empty → null', () => expect(requiredError('x'), isNull));
    test('names the field', () {
      expect(requiredError('', field: 'Full name'), contains('Full name'));
    });
  });

  group('emailError', () {
    for (final bad in const [
      '',
      'abc',
      'a@b',
      'a@b.',
      '@example.com',
      'a b@example.com',
    ]) {
      test('rejects "$bad"', () => expect(emailError(bad), isNotNull));
    }
    for (final ok in const [
      'david.miller@example.com',
      'a+b@sub.domain.co',
    ]) {
      test('accepts "$ok"', () => expect(emailError(ok), isNull));
    }
  });

  group('phoneError', () {
    for (final bad in const ['', '12345', '(555) 019']) {
      test('rejects "$bad"', () => expect(phoneError(bad), isNotNull));
    }
    for (final ok in const [
      '(555) 019-8234',
      '+1 555 019 8234',
      '5550198234',
    ]) {
      test('accepts "$ok"', () => expect(phoneError(ok), isNull));
    }
  });

  group('positiveNumberError', () {
    for (final bad in const ['', 'abc', '0', '-3']) {
      test('rejects "$bad"', () => expect(positiveNumberError(bad), isNotNull));
    }
    test('accepts "85"', () => expect(positiveNumberError('85'), isNull));
    test('accepts "72.5"', () => expect(positiveNumberError('72.5'), isNull));
  });

  group('ageError', () {
    for (final bad in const ['', 'abc', '0', '150', '-1', '48.5']) {
      test('rejects "$bad"', () => expect(ageError(bad), isNotNull));
    }
    test('accepts "48"', () => expect(ageError('48'), isNull));
    test('accepts boundaries "1" and "149"', () {
      expect(ageError('1'), isNull);
      expect(ageError('149'), isNull);
    });
  });
}
