import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ReportHeaderOrganism extends StatelessWidget {
  final String title;
  final String date;

  const ReportHeaderOrganism({
    super.key,
    this.title = "Nocturnal Session Report",
    this.date = "Sep 1, 2026",
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          date,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
