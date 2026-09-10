import 'package:equatable/equatable.dart';
import '../../profile/user_profile.dart';

/// State for [ProfileBloc] — the medical-profile field values and the derived
/// BMI. Starts empty; `ProfileBloc` seeds it from a `UserProfile` (via
/// [ProfileState.fromProfile]) when one is available. The `TextEditingController`s
/// stay in the view and feed values in via `ProfileFieldChanged`.
class ProfileState extends Equatable {
  final String name;
  final String email;
  final String phone;
  final String age;
  final String weight;
  final String height;
  final String caregiverName;
  final String emergencyPhone;
  final double computedBmi;

  const ProfileState({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.age = '',
    this.weight = '',
    this.height = '',
    this.caregiverName = '',
    this.emergencyPhone = '',
    this.computedBmi = 0,
  });

  /// Seed the form from a loaded [UserProfile]. Numeric fields render without a
  /// trailing `.0`; `computedBmi` is taken straight from the profile.
  factory ProfileState.fromProfile(UserProfile p) => ProfileState(
        name: p.fullName,
        email: p.email,
        phone: p.phone,
        age: p.age == 0 ? '' : p.age.toString(),
        weight: _num(p.weightKg),
        height: _num(p.heightCm),
        caregiverName: p.caregiverName,
        emergencyPhone: p.caregiverPhone,
        computedBmi: p.computedBmi,
      );

  static String _num(double d) {
    if (d == 0) return '';
    return d % 1 == 0 ? d.toInt().toString() : d.toString();
  }

  ProfileState copyWith({
    String? name,
    String? email,
    String? phone,
    String? age,
    String? weight,
    String? height,
    String? caregiverName,
    String? emergencyPhone,
    double? computedBmi,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      caregiverName: caregiverName ?? this.caregiverName,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      computedBmi: computedBmi ?? this.computedBmi,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        age,
        weight,
        height,
        caregiverName,
        emergencyPhone,
        computedBmi,
      ];
}
