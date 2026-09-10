import 'package:flutter/material.dart';
import '../../core/bloc/history/history_state.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/shad_badge.dart';

class HomeSummaryCard extends StatelessWidget {
  final String dateText;
  final double apneaIndex;
  final String durationText;
  final int eventCount;
  final bool alarmFired;
  final int alarmCount;
  final bool isEmpty;
  final VoidCallback? onTap;

  const HomeSummaryCard({
    super.key,
    this.dateText = "Sep 5, 2026",
    this.apneaIndex = 3.2,
    this.durationText = "7h 45m",
    this.eventCount = 2,
    this.alarmFired = false,
    this.alarmCount = 1,
    this.isEmpty = false,
    this.onTap,
  });

  ShadBadgeVariant _getBadgeVariant() {
    if (alarmFired) return ShadBadgeVariant.amberAlert;
    switch (HistoryState.severityFor(apneaIndex)) {
      case HistorySeverity.normal:
        return ShadBadgeVariant.normal;
      case HistorySeverity.mild:
      case HistorySeverity.moderate:
        return ShadBadgeVariant.moderate;
      case HistorySeverity.severe:
        return ShadBadgeVariant.severe;
    }
  }

  String _getBadgeLabel() {
    if (alarmFired) {
      return alarmCount == 1 ? "1 apnea alert" : "$alarmCount apnea alerts";
    }
    switch (HistoryState.severityFor(apneaIndex)) {
      case HistorySeverity.normal:
        return "Normal";
      case HistorySeverity.mild:
        return "Mild";
      case HistorySeverity.moderate:
        return "Moderate";
      case HistorySeverity.severe:
        return "Severe";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          children: const [
            Icon(Icons.nightlight_round_outlined, size: 28, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text(
              "No sleep sessions recorded yet",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "LAST NIGHT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.04,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Hero Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        apneaIndex.toStringAsFixed(1),
                        style: AppTheme.tabularTextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "AI",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      ShadBadge(
                        label: _getBadgeLabel(),
                        variant: _getBadgeVariant(),
                        icon: alarmFired
                            ? const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.warningAmber)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Secondary Stats Row
                  Row(
                    children: [
                      const Text(
                        "Duration ",
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        durationText,
                        style: AppTheme.tabularTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("·", style: TextStyle(color: AppColors.cardBorder, fontWeight: FontWeight.bold)),
                      ),
                      const Text(
                        "Apnea events ",
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      Text(
                        "$eventCount",
                        style: AppTheme.tabularTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: alarmFired ? AppColors.warningAmber : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
