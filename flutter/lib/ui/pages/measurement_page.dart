import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../organisms/live_waveform_chart.dart';

class MeasurementPage extends StatelessWidget {
  const MeasurementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Overnight Sleep Recording", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BLE Status Chip Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bluetooth, color: AppColors.primaryTeal, size: 20),
                        SizedBox(width: 8),
                        Text("Breathing Device", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: const [
                        Icon(Icons.check_circle, color: AppColors.accentGreen, size: 16),
                        SizedBox(width: 4),
                        Text("Ready for Sleep", style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Live Respiratory Airflow Waveform Chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Live Sleep Airflow Stream", style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
                  Text("Status: Recording", style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 10),
              LiveWaveformChart(
                points: const [
                  FlSpot(0, 0),
                  FlSpot(1, 1.2),
                  FlSpot(2, -1.0),
                  FlSpot(3, 1.5),
                  FlSpot(4, -0.5),
                  FlSpot(5, 1.8),
                  FlSpot(6, -1.2),
                  FlSpot(7, 0.8),
                  FlSpot(8, -0.2),
                  FlSpot(9, 1.1),
                  FlSpot(10, 0),
                ],
              ),
              const SizedBox(height: 24),

              // Sleep Mode Information Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bedtime, color: AppColors.primaryTeal, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Sleep Apnea Monitoring Active", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 4),
                          Text("Leave the app running while sleeping. Your morning summary will be ready upon waking up.", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
