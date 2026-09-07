import 'package:equatable/equatable.dart';

/// AI-severity band for a session's Apnea Index (apnea-only). Mirrors the
/// thresholds `_HistoryFilterPageState` used inline for both the filter and the
/// row badge.
enum HistorySeverity { normal, moderate, severe }

class HistoryState extends Equatable {
  final int selectedFilterIndex;
  final List<Map<String, dynamic>> allSessions;

  const HistoryState({
    this.selectedFilterIndex = 0,
    this.allSessions = _seedSessions,
  });

  static const List<Map<String, dynamic>> _seedSessions = [
    {"date": "Sep 5, 2026", "duration": "7h 45m", "ai": 3.2, "events": 2, "status": "Normal"},
    {"date": "Sep 4, 2026", "duration": "8h 10m", "ai": 3.8, "events": 3, "status": "Normal"},
    {"date": "Sep 3, 2026", "duration": "6h 50m", "ai": 4.0, "events": 3, "status": "Normal"},
    {"date": "Sep 1, 2026", "duration": "7h 15m", "ai": 3.5, "events": 2, "status": "Normal"},
    {"date": "Aug 31, 2026", "duration": "7h 30m", "ai": 16.4, "events": 14, "status": "Moderate"},
    {"date": "Aug 30, 2026", "duration": "8h 05m", "ai": 2.9, "events": 2, "status": "Normal"},
  ];

  /// The sessions visible under the current chip — identical to
  /// `_filteredSessions`.
  List<Map<String, dynamic>> get filteredSessions {
    if (selectedFilterIndex == 1) {
      return allSessions.where((s) => (s['ai'] as double) < 5.0).toList();
    } else if (selectedFilterIndex == 2) {
      return allSessions
          .where((s) =>
              (s['ai'] as double) >= 5.0 && (s['ai'] as double) < 30.0)
          .toList();
    } else if (selectedFilterIndex == 3) {
      return allSessions.where((s) => (s['ai'] as double) >= 30.0).toList();
    }
    return allSessions;
  }

  /// Row-badge banding: `>= 30` severe, `>= 5` moderate, else normal.
  static HistorySeverity severityFor(double ai) {
    if (ai >= 30.0) return HistorySeverity.severe;
    if (ai >= 5.0) return HistorySeverity.moderate;
    return HistorySeverity.normal;
  }

  HistoryState copyWith({int? selectedFilterIndex}) => HistoryState(
        selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
        allSessions: allSessions,
      );

  @override
  List<Object?> get props => [selectedFilterIndex, allSessions];
}
