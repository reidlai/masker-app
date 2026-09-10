import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/profile/profile_bloc.dart';
import 'package:masker_app/core/bloc/profile/profile_event.dart';
import 'package:masker_app/core/bloc/profile/profile_state.dart';
import 'package:masker_app/core/profile/user_profile.dart';

const _seed = UserProfile(
  userId: 'u1',
  fullName: 'David Miller',
  weightKg: 85,
  heightCm: 178,
  computedBmi: 26.8,
);

ProfileBloc _seededBloc() => ProfileBloc(initial: _seed);

void main() {
  test('no initial → empty state', () {
    final bloc = ProfileBloc();
    expect(bloc.state, const ProfileState());
    expect(bloc.state.name, '');
    expect(bloc.state.weight, '');
    expect(bloc.state.computedBmi, 0);
    bloc.close();
  });

  test('initial UserProfile seeds the form fields + BMI', () {
    final bloc = _seededBloc();
    expect(bloc.state.name, 'David Miller');
    expect(bloc.state.weight, '85');
    expect(bloc.state.height, '178');
    expect(bloc.state.computedBmi, 26.8);
    bloc.close();
  });

  blocTest<ProfileBloc, ProfileState>(
    'a non-BMI field change updates only that field, BMI untouched',
    build: _seededBloc,
    act: (bloc) =>
        bloc.add(const ProfileFieldChanged(ProfileField.name, 'Dana Fox')),
    verify: (bloc) {
      expect(bloc.state.name, 'Dana Fox');
      expect(bloc.state.computedBmi, 26.8);
    },
  );

  blocTest<ProfileBloc, ProfileState>(
    'weight change re-derives BMI exactly as _calculateBmi() did (90kg -> 28.4)',
    build: _seededBloc,
    act: (bloc) =>
        bloc.add(const ProfileFieldChanged(ProfileField.weight, '90')),
    verify: (bloc) {
      expect(bloc.state.weight, '90');
      expect(bloc.state.computedBmi.toStringAsFixed(1), '28.4');
    },
  );

  blocTest<ProfileBloc, ProfileState>(
    'non-numeric weight leaves the last valid BMI in place',
    build: _seededBloc,
    act: (bloc) =>
        bloc.add(const ProfileFieldChanged(ProfileField.weight, 'abc')),
    verify: (bloc) {
      expect(bloc.state.weight, 'abc');
      expect(bloc.state.computedBmi, 26.8);
    },
  );

  blocTest<ProfileBloc, ProfileState>(
    'height <= 0 does not divide-by-zero — BMI unchanged',
    build: _seededBloc,
    act: (bloc) =>
        bloc.add(const ProfileFieldChanged(ProfileField.height, '0')),
    verify: (bloc) => expect(bloc.state.computedBmi, 26.8),
  );
}
