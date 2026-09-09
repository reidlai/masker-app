import 'package:equatable/equatable.dart';

/// The patient's identity + health baseline, as held by [UserProfileService].
///
/// Fields mirror the `PatientUser` + `HealthBaseline` entities in the
/// architecture spine. Nothing populates this in the current slice — the store
/// only ever holds `null` (empty) or a value set by a later fetch path.
class UserProfile extends Equatable {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final int age;
  final String gender;
  final double weightKg;
  final double heightCm;
  final double computedBmi;
  final String caregiverName;
  final String caregiverPhone;

  const UserProfile({
    required this.userId,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.age = 0,
    this.gender = '',
    this.weightKg = 0,
    this.heightCm = 0,
    this.computedBmi = 0,
    this.caregiverName = '',
    this.caregiverPhone = '',
  });

  @override
  List<Object?> get props => [
        userId,
        fullName,
        email,
        phone,
        age,
        gender,
        weightKg,
        heightCm,
        computedBmi,
        caregiverName,
        caregiverPhone,
      ];
}
