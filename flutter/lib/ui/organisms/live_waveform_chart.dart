import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

class LiveWaveformChart extends StatelessWidget {
  final List<FlSpot>? points;
  final bool showApneaMarkers;

  const LiveWaveformChart({
    super.key,
    this.points,
    this.showApneaMarkers = true,
  });

  List<FlSpot> _getDefaultSamplePoints() {
    return const [
      FlSpot(0, 0.5),
      FlSpot(1, 1.8),
      FlSpot(2, 0.5),
      FlSpot(3, 0.4),
      FlSpot(4, 0.5),
      FlSpot(5, -0.8), // Apnea Event Dip
      FlSpot(6, 0.5),
      FlSpot(7, 1.9),
      FlSpot(8, 0.5),
      FlSpot(9, 0.5),
      FlSpot(10, 1.7),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> displayPoints = points ?? _getDefaultSamplePoints();

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Respiration Waveform (Skia 60 FPS)",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                "10Hz Stream",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.cardBorder, strokeWidth: 1, dashArray: [4, 4]),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 10,
                minY: -1.5,
                maxY: 2.5,
                lineBarsData: [
                  LineChartBarData(
                    spots: displayPoints,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.accentGreen,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: showApneaMarkers,
                      checkToShowDot: (spot, barData) => spot.y < 0.0,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: AppColors.dangerRed,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accentGreen.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
