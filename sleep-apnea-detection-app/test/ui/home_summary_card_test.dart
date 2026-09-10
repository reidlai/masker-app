import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/ui/atoms/shad_badge.dart';
import 'package:masker_app/ui/molecules/home_summary_card.dart';

/// The hero card derives its status pill from `HistoryState.severityFor`
/// (4-band: Normal <5 / Mild 5–15 / Moderate 15–30 / Severe ≥30). These pin the
/// label + `ShadBadge` variant per band and at each boundary so a wrong mapping
/// on the app's home screen cannot ship green.
void main() {
  Future<ShadBadge> pumpAndReadBadge(
    WidgetTester tester, {
    required double apneaIndex,
    bool alarmFired = false,
    int alarmCount = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSummaryCard(
            apneaIndex: apneaIndex,
            alarmFired: alarmFired,
            alarmCount: alarmCount,
          ),
        ),
      ),
    );
    return tester.widget<ShadBadge>(find.byType(ShadBadge));
  }

  final cases = <String, ({double ai, String label, ShadBadgeVariant variant})>{
    'Normal': (ai: 3.2, label: 'Normal', variant: ShadBadgeVariant.normal),
    'Mild': (ai: 9.4, label: 'Mild', variant: ShadBadgeVariant.moderate),
    'Moderate': (ai: 16.4, label: 'Moderate', variant: ShadBadgeVariant.moderate),
    'Severe': (ai: 42.0, label: 'Severe', variant: ShadBadgeVariant.severe),
    // boundaries — lower band wins, upper bound exclusive
    'just below Mild (4.99)': (ai: 4.99, label: 'Normal', variant: ShadBadgeVariant.normal),
    'Mild lower edge (5.0)': (ai: 5.0, label: 'Mild', variant: ShadBadgeVariant.moderate),
    'just below Moderate (14.99)': (ai: 14.99, label: 'Mild', variant: ShadBadgeVariant.moderate),
    'Moderate lower edge (15.0)': (ai: 15.0, label: 'Moderate', variant: ShadBadgeVariant.moderate),
    'just below Severe (29.99)': (ai: 29.99, label: 'Moderate', variant: ShadBadgeVariant.moderate),
    'Severe lower edge (30.0)': (ai: 30.0, label: 'Severe', variant: ShadBadgeVariant.severe),
  };

  cases.forEach((name, c) {
    testWidgets('$name band: "${c.label}" label + ${c.variant} variant', (tester) async {
      final badge = await pumpAndReadBadge(tester, apneaIndex: c.ai);
      expect(badge.label, c.label);
      expect(badge.variant, c.variant);
    });
  });

  testWidgets('alarm_fired overrides the band pill regardless of AI', (tester) async {
    final badge = await pumpAndReadBadge(tester, apneaIndex: 3.2, alarmFired: true, alarmCount: 2);
    expect(badge.label, '2 apnea alerts');
    expect(badge.variant, ShadBadgeVariant.amberAlert);
  });

  testWidgets('empty state renders no severity badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeSummaryCard(isEmpty: true)),
      ),
    );
    expect(find.byType(ShadBadge), findsNothing);
    expect(find.text('No sleep sessions recorded yet'), findsOneWidget);
  });
}
