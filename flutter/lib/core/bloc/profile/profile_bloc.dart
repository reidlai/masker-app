import 'package:flutter_bloc/flutter_bloc.dart';
import '../../profile/user_profile.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// Owns the medical-profile field values and the derived BMI — the domain math
/// (`_calculateBmi()`) lifted out of `_ProfilePageState` unchanged. A
/// non-numeric weight/height leaves the last valid BMI in place.
///
/// Seeded from [initial] when the profile store has a value; otherwise starts
/// empty (a blank "complete your profile" form).
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({UserProfile? initial})
      : super(initial != null
            ? ProfileState.fromProfile(initial)
            : const ProfileState()) {
    on<ProfileFieldChanged>(_onFieldChanged);
  }

  void _onFieldChanged(ProfileFieldChanged event, Emitter<ProfileState> emit) {
    var next = state;
    switch (event.field) {
      case ProfileField.name:
        next = next.copyWith(name: event.value);
        break;
      case ProfileField.email:
        next = next.copyWith(email: event.value);
        break;
      case ProfileField.phone:
        next = next.copyWith(phone: event.value);
        break;
      case ProfileField.age:
        next = next.copyWith(age: event.value);
        break;
      case ProfileField.weight:
        next = next.copyWith(weight: event.value);
        break;
      case ProfileField.height:
        next = next.copyWith(height: event.value);
        break;
      case ProfileField.caregiverName:
        next = next.copyWith(caregiverName: event.value);
        break;
      case ProfileField.emergencyPhone:
        next = next.copyWith(emergencyPhone: event.value);
        break;
    }

    if (event.field == ProfileField.weight ||
        event.field == ProfileField.height) {
      final double? weight = double.tryParse(next.weight);
      final double? heightCm = double.tryParse(next.height);
      if (weight != null && heightCm != null && heightCm > 0) {
        final double heightM = heightCm / 100.0;
        next = next.copyWith(computedBmi: weight / (heightM * heightM));
      }
    }

    emit(next);
  }
}
