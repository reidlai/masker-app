import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HistoryTile extends StatelessWidget {
  final String date;
  final String time;
  final String duration;
  final String spO2;
  final String heartRate;

  const HistoryTile({
    super.key,
    required this.date,
    required this.time,
    required this.duration,
    required this.spO2,
    required this.heartRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Date", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text(date, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Time", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text(time, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Dur.", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text(duration, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.cardBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SpO2: $spO2%", style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
              Text("HR: $heartRate bpm", style: const TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
