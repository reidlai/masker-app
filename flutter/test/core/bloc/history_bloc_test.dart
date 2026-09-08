import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/history/history_bloc.dart';
import 'package:masker_app/core/bloc/history/history_event.dart';
import 'package:masker_app/core/bloc/history/history_state.dart';

void main() {
  test('initial state: filter "All", full seed list of 6 sessions', () {
    final bloc = HistoryBloc();
    expect(bloc.state.selectedFilterIndex, 0);
    expect(bloc.state.filteredSessions.length, 6);
    bloc.close();
  });

  blocTest<HistoryBloc, HistoryState>(
    'Normal (index 1) keeps only AI < 5 sessions',
    build: HistoryBloc.new,
    act: (bloc) => bloc.add(const HistoryFilterSelected(1)),
    expect: () => [const HistoryState(selectedFilterIndex: 1)],
    verify: (bloc) {
      final filtered = bloc.state.filteredSessions;
      expect(filtered.length, 4);
      expect(filtered.every((s) => (s['ai'] as double) < 5.0), isTrue);
    },
  );

  blocTest<HistoryBloc, HistoryState>(
    'Mild (index 2) keeps only 5 <= AI < 15 sessions',
    build: HistoryBloc.new,
    act: (bloc) => bloc.add(const HistoryFilterSelected(2)),
    expect: () => [const HistoryState(selectedFilterIndex: 2)],
    verify: (bloc) {
      final filtered = bloc.state.filteredSessions;
      expect(filtered.map((s) => s['date']), ['Sep 3, 2026']);
      expect(
        filtered.every((s) =>
            (s['ai'] as double) >= 5.0 && (s['ai'] as double) < 15.0),
        isTrue,
      );
    },
  );

  blocTest<HistoryBloc, HistoryState>(
    'Moderate (index 3) keeps only 15 <= AI < 30 sessions',
    build: HistoryBloc.new,
    act: (bloc) => bloc.add(const HistoryFilterSelected(3)),
    expect: () => [const HistoryState(selectedFilterIndex: 3)],
    verify: (bloc) {
      final filtered = bloc.state.filteredSessions;
      expect(filtered.map((s) => s['date']), ['Aug 31, 2026']);
    },
  );

  blocTest<HistoryBloc, HistoryState>(
    'Severe (index 4) keeps only AI >= 30 sessions (none in seed)',
    build: HistoryBloc.new,
    act: (bloc) => bloc.add(const HistoryFilterSelected(4)),
    verify: (bloc) => expect(bloc.state.filteredSessions, isEmpty),
  );

  test('severityFor uses the 4-band thresholds', () {
    expect(HistoryState.severityFor(2.9), HistorySeverity.normal);
    expect(HistoryState.severityFor(9.4), HistorySeverity.mild);
    expect(HistoryState.severityFor(16.4), HistorySeverity.moderate);
    expect(HistoryState.severityFor(42.0), HistorySeverity.severe);
  });

  test('severityFor boundaries: lower band wins, upper bound exclusive', () {
    expect(HistoryState.severityFor(4.99), HistorySeverity.normal);
    expect(HistoryState.severityFor(5.0), HistorySeverity.mild);
    expect(HistoryState.severityFor(14.99), HistorySeverity.mild);
    expect(HistoryState.severityFor(15.0), HistorySeverity.moderate);
    expect(HistoryState.severityFor(29.99), HistorySeverity.moderate);
    expect(HistoryState.severityFor(30.0), HistorySeverity.severe);
  });

  test('severityFor guards invalid AI (NaN / negative) as normal', () {
    expect(HistoryState.severityFor(double.nan), HistorySeverity.normal);
    expect(HistoryState.severityFor(-1.0), HistorySeverity.normal);
  });
}
