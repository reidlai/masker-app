import 'package:equatable/equatable.dart';

/// Editable medical-profile fields.
enum ProfileField {
  name,
  email,
  phone,
  age,
  weight,
  height,
  caregiverName,
  emergencyPhone,
}

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => const [];
}

/// A profile field's value changed in the view. Weight / height changes
/// re-derive the BMI exactly as `_calculateBmi()` did.
class ProfileFieldChanged extends ProfileEvent {
  final ProfileField field;
  final String value;
  const ProfileFieldChanged(this.field, this.value);

  @override
  List<Object?> get props => [field, value];
}
