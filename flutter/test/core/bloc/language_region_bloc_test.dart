import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/language_region/language_region_bloc.dart';
import 'package:masker_app/core/bloc/language_region/language_region_event.dart';
import 'package:masker_app/core/bloc/language_region/language_region_state.dart';

void main() {
  test('initial state carries the seed selections + option lists', () {
    final bloc = LanguageRegionBloc();
    expect(bloc.state, const LanguageRegionState());
    expect(bloc.state.selectedLanguage, 'English (US)');
    expect(bloc.state.selectedRegion, 'United States');
    expect(bloc.state.selectedUnits, 'Metric (kg, cm)');
    expect(bloc.state.languages, contains('English (UK)'));
    bloc.close();
  });

  blocTest<LanguageRegionBloc, LanguageRegionState>(
    'language selection is reflected in state',
    build: LanguageRegionBloc.new,
    act: (bloc) =>
        bloc.add(const LanguageRegionLanguageSelected('English (UK)')),
    expect: () =>
        [const LanguageRegionState(selectedLanguage: 'English (UK)')],
  );

  blocTest<LanguageRegionBloc, LanguageRegionState>(
    'region + units selections compose without disturbing the others',
    build: LanguageRegionBloc.new,
    act: (bloc) => bloc
      ..add(const LanguageRegionRegionSelected('Canada'))
      ..add(const LanguageRegionUnitsSelected('Imperial (lb, in)')),
    expect: () => [
      const LanguageRegionState(selectedRegion: 'Canada'),
      const LanguageRegionState(
        selectedRegion: 'Canada',
        selectedUnits: 'Imperial (lb, in)',
      ),
    ],
  );
}
