import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

class LiveWaveformChart extends StatelessWidget {
  final List<FlSpot> points;

  const LiveWaveformChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.cardBorder, strokeWidth: 1),
            getDrawingVerticalLine: (value) => const FlLine(color: AppColors.cardBorder, strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 10,
          minY: -2,
          maxY: 2,
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              color: AppColors.primaryTeal,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryTeal.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
