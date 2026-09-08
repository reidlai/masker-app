import 'package:equatable/equatable.dart';

/// Severity band for a session's Apnea Index (apnea-only). The 4-band scheme
/// (Normal / Mild / Moderate / Severe) is the standard clinical severity banding
/// applied to the apnea-only index; `severityFor` is the single source of truth.
enum HistorySeverity { normal, mild, moderate, severe }

class HistoryState extends Equatable {
  final int selectedFilterIndex;
  final List<Map<String, dynamic>> allSessions;

  const HistoryState({
    this.selectedFilterIndex = 0,
    this.allSessions = _seedSessions,
  });

  // `ai` is the source of truth for a row's severity; the badge and filter both
  // derive it via [severityFor]. No stored `status` string — it would be a
  // second, un-checked source of truth (see the "ONE place" note on severityFor).
  static const List<Map<String, dynamic>> _seedSessions = [
    {"date": "Sep 5, 2026", "duration": "7h 45m", "ai": 3.2, "events": 2},
    {"date": "Sep 4, 2026", "duration": "8h 10m", "ai": 3.8, "events": 3},
    {"date": "Sep 3, 2026", "duration": "6h 50m", "ai": 9.4, "events": 8},
    {"date": "Sep 1, 2026", "duration": "7h 15m", "ai": 3.5, "events": 2},
    {"date": "Aug 31, 2026", "duration": "7h 30m", "ai": 16.4, "events": 14},
    {"date": "Aug 30, 2026", "duration": "8h 05m", "ai": 2.9, "events": 2},
  ];

  /// The sessions visible under the current chip. Chip indices:
  /// All=0, Normal=1 (`ai < 5`), Mild=2 (`5 <= ai < 15`),
  /// Moderate=3 (`15 <= ai < 30`), Severe=4 (`ai >= 30`). Band membership is
  /// derived from [severityFor] so the chips and the row badges cannot diverge.
  List<Map<String, dynamic>> get filteredSessions {
    HistorySeverity? target;
    switch (selectedFilterIndex) {
      case 1:
        target = HistorySeverity.normal;
        break;
      case 2:
        target = HistorySeverity.mild;
        break;
      case 3:
        target = HistorySeverity.moderate;
        break;
      case 4:
        target = HistorySeverity.severe;
        break;
      default:
        target = null;
    }
    if (target == null) return allSessions;
    return allSessions
        .where((s) => severityFor((s['ai'] as num).toDouble()) == target)
        .toList();
  }

  /// The ONE place AI-severity bands are defined. 4-band thresholds:
  /// Normal `ai < 5`, Mild `5 <= ai < 15`, Moderate `15 <= ai < 30`,
  /// Severe `ai >= 30`. Upper bound exclusive; the lower band wins at the
  /// boundary. Invalid input (`NaN` or `< 0`) is treated as `normal`.
  static HistorySeverity severityFor(double ai) {
    if (ai.isNaN || ai < 0) return HistorySeverity.normal;
    if (ai >= 30.0) return HistorySeverity.severe;
    if (ai >= 15.0) return HistorySeverity.moderate;
    if (ai >= 5.0) return HistorySeverity.mild;
    return HistorySeverity.normal;
  }

  HistoryState copyWith({int? selectedFilterIndex}) => HistoryState(
        selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
        allSessions: allSessions,
      );

  @override
  List<Object?> get props => [selectedFilterIndex, allSessions];
}
