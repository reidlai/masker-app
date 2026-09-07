import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/profile/profile_bloc.dart';
import 'package:masker_app/core/bloc/profile/profile_event.dart';
import 'package:masker_app/core/bloc/profile/profile_state.dart';

void main() {
  test('initial state carries the seed demographics + seed BMI', () {
    final bloc = ProfileBloc();
    expect(bloc.state, const ProfileState());
    expect(bloc.state.weight, '85');
    expect(bloc.state.height, '178');
    expect(bloc.state.computedBmi, 26.8);
    bloc.close();
  });

  blocTest<ProfileBloc, ProfileState>(
    'a non-BMI field change updates only that field, BMI untouched',
    build: ProfileBloc.new,
    act: (bloc) =>
        bloc.add(const ProfileFieldChanged(ProfileField.name, 'Dana Fox')),
    expect: () => [
      const ProfileState(name: 'Dana Fox'),
    ],
    verify: (bloc) => expect(bloc.state.computedBmi, 26.8),
  );

  blocTest<ProfileBloc, ProfileState>(
    'weight change re-derives BMI exactly as _calculateBmi() did (90kg -> 28.4)',
    build: ProfileBloc.new,
    act: (bloc) =>
        bloc.add(const ProfileFieldChanged(ProfileField.weight, '90')),
    verify: (bloc) {
      expect(bloc.state.weight, '90');
      expect(bloc.state.computedBmi.toStringAsFixed(1), '28.4');
    },
  );

  blocTest<ProfileBloc, ProfileState>(
    'non-numeric weight leaves the last valid BMI in place',
    build: ProfileBloc.new,
    act: (bloc) =>
        bloc.add(const ProfileFieldChanged(ProfileField.weight, 'abc')),
    verify: (bloc) {
      expect(bloc.state.weight, 'abc');
      expect(bloc.state.computedBmi, 26.8);
    },
  );

  blocTest<ProfileBloc, ProfileState>(
    'height <= 0 does not divide-by-zero — BMI unchanged',
    build: ProfileBloc.new,
    act: (bloc) =>
        bloc.add(const ProfileFieldChanged(ProfileField.height, '0')),
    verify: (bloc) => expect(bloc.state.computedBmi, 26.8),
  );
}
