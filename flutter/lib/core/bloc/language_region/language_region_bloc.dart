import 'package:flutter_bloc/flutter_bloc.dart';
import 'language_region_event.dart';
import 'language_region_state.dart';

/// Owns the Language & Region selections and their option lists — the seed
/// values lifted out of `_LanguageRegionPageState` unchanged.
class LanguageRegionBloc
    extends Bloc<LanguageRegionEvent, LanguageRegionState> {
  LanguageRegionBloc() : super(const LanguageRegionState()) {
    on<LanguageRegionLanguageSelected>(
      (event, emit) => emit(state.copyWith(selectedLanguage: event.value)),
    );
    on<LanguageRegionRegionSelected>(
      (event, emit) => emit(state.copyWith(selectedRegion: event.value)),
    );
    on<LanguageRegionUnitsSelected>(
      (event, emit) => emit(state.copyWith(selectedUnits: event.value)),
    );
  }
}
