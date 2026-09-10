import 'package:equatable/equatable.dart';

class LanguageRegionState extends Equatable {
  final String selectedLanguage;
  final String selectedRegion;
  final String selectedUnits;
  final List<String> languages;
  final List<String> regions;
  final List<String> units;

  const LanguageRegionState({
    this.selectedLanguage = 'English (US)',
    this.selectedRegion = 'United States',
    this.selectedUnits = 'Metric (kg, cm)',
    this.languages = _seedLanguages,
    this.regions = _seedRegions,
    this.units = _seedUnits,
  });

  static const List<String> _seedLanguages = [
    "English (US)",
    "English (UK)",
    "Spanish (Español)",
    "German (Deutsch)",
    "French (Français)",
  ];

  static const List<String> _seedRegions = [
    "United States",
    "United Kingdom",
    "European Union",
    "Canada",
    "Australia",
  ];

  static const List<String> _seedUnits = [
    "Metric (kg, cm)",
    "Imperial (lb, in)",
  ];

  LanguageRegionState copyWith({
    String? selectedLanguage,
    String? selectedRegion,
    String? selectedUnits,
  }) {
    return LanguageRegionState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedUnits: selectedUnits ?? this.selectedUnits,
      languages: languages,
      regions: regions,
      units: units,
    );
  }

  @override
  List<Object?> get props => [
        selectedLanguage,
        selectedRegion,
        selectedUnits,
        languages,
        regions,
        units,
      ];
}
