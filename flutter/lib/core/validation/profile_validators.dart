// Pure, host-agnostic validators for the medical-profile form (Story 1.11).
//
// Each returns `null` when the value is acceptable, or a short user-facing
// message naming the problem. Shared by `ProfileForm` (both the Settings edit
// host and the onboarding wizard step) and their unit tests, so the rules
// live in exactly one place.

String? requiredError(String value, {String field = 'This field'}) {
  return value.trim().isEmpty ? '$field is required' : null;
}

// Pragmatic RFC 5322 subset (the HTML5 email regex) — not the full grammar.
final RegExp _emailRe = RegExp(
  r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
  r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
  r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
);

String? emailError(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Email address is required';
  return _emailRe.hasMatch(v) ? null : 'Enter a valid email address';
}

String? phoneError(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Phone number is required';
  final digits = v.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 10 ? null : 'Enter a valid phone number';
}

String? positiveNumberError(String value, {String field = 'Value'}) {
  final v = value.trim();
  if (v.isEmpty) return '$field is required';
  final n = double.tryParse(v);
  if (n == null) return 'Enter a number';
  return n > 0 ? null : '$field must be greater than 0';
}

String? ageError(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Age is required';
  final n = int.tryParse(v);
  if (n == null) return 'Enter a whole number';
  return (n >= 1 && n <= 149) ? null : 'Enter an age between 1 and 149';
}
