import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HealthInsightsOrganism extends StatelessWidget {
  final VoidCallback? onArticle1Tap;
  final VoidCallback? onArticle2Tap;

  const HealthInsightsOrganism({
    super.key,
    this.onArticle1Tap,
    this.onArticle2Tap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Health & Mask Insights",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onArticle1Tap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.article, color: AppColors.primaryTeal, size: 32),
                      SizedBox(height: 8),
                      Text("Mask Use & Health", style: TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onArticle2Tap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.monitor_heart, color: AppColors.accentGreen, size: 32),
                      SizedBox(height: 8),
                      Text("Understanding SpO2", style: TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
