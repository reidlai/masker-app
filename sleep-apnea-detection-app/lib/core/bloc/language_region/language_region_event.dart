import 'package:equatable/equatable.dart';

abstract class LanguageRegionEvent extends Equatable {
  const LanguageRegionEvent();

  @override
  List<Object?> get props => const [];
}

class LanguageRegionLanguageSelected extends LanguageRegionEvent {
  final String value;
  const LanguageRegionLanguageSelected(this.value);

  @override
  List<Object?> get props => [value];
}

class LanguageRegionRegionSelected extends LanguageRegionEvent {
  final String value;
  const LanguageRegionRegionSelected(this.value);

  @override
  List<Object?> get props => [value];
}

class LanguageRegionUnitsSelected extends LanguageRegionEvent {
  final String value;
  const LanguageRegionUnitsSelected(this.value);

  @override
  List<Object?> get props => [value];
}
