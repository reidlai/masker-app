import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WeeklyTrendCard extends StatelessWidget {
  final List<double?> weeklyScores; // 7 slots, null for missed night
  final double averageScore;
  final double priorWeekScore;
  final VoidCallback? onTap;

  const WeeklyTrendCard({
    super.key,
    this.weeklyScores = const [2.8, 3.1, 4.0, null, 3.5, 3.8, 3.2],
    this.averageScore = 3.4,
    this.priorWeekScore = 4.1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double diff = averageScore - priorWeekScore;
    String deltaText;
    Color deltaColor;

    if (diff < -0.1) {
      deltaText = "down from ${priorWeekScore.toStringAsFixed(1)} last week";
      deltaColor = AppColors.accentGreen;
    } else if (diff > 0.1) {
      deltaText = "up from ${priorWeekScore.toStringAsFixed(1)} last week";
      deltaColor = AppColors.warningAmber;
    } else {
      deltaText = "level with last week";
      deltaColor = AppColors.textSecondary;
    }

    // Find max score for bar scaling (min max is 5.0)
    final double maxScore = weeklyScores.whereType<double>().fold(5.0, (prev, val) => val > prev ? val : prev);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "APNEA INDEX — LAST 7 NIGHTS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.04,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 7-Bar Chart Strip
            SizedBox(
              height: 56,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final score = index < weeklyScores.length ? weeklyScores[index] : null;
                  final bool isLatest = index == 6;

                  if (score == null) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.cardBorder, width: 1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }

                  final double heightFactor = (score / maxScore).clamp(0.15, 1.0);

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 56 * heightFactor,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: isLatest ? 1.0 : 0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),
            // Delta Line
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                children: [
                  TextSpan(
                    text: "${averageScore.toStringAsFixed(1)} average",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(
                    text: " · ",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: deltaText,
                    style: TextStyle(color: deltaColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
