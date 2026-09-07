import 'package:equatable/equatable.dart';

/// State for [ProfileBloc] — the medical-profile field values and the derived
/// BMI. Seed values that used to be literals inside `_ProfilePageState` are the
/// initial state here; the `TextEditingController`s stay in the view and feed
/// their values in via `ProfileFieldChanged`.
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
    this.name = 'David Miller',
    this.email = 'david.miller@example.com',
    this.phone = '(555) 019-8234',
    this.age = '48',
    this.weight = '85',
    this.height = '178',
    this.caregiverName = 'Maria Chen',
    this.emergencyPhone = '(555) 019-2244',
    this.computedBmi = 26.8,
  });

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
