import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';
import '../organisms/live_waveform_chart.dart';
import '../organisms/report_header_organism.dart';
import '../organisms/sleep_score_organism.dart';
import '../organisms/summary_metrics_grid_organism.dart';

class SummaryScreenPage extends StatelessWidget {
  const SummaryScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Morning Sleep Summary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Date Organism
              const ReportHeaderOrganism(),
              const SizedBox(height: 16),

              // Sleep Score Organism
              const SleepScoreOrganism(
                score: 92,
                ahiValue: "3.2",
                ahiStatus: "Normal",
                durationText: "7 Hours 45 Mins Monitoring",
                badgeText: "NORMAL RESPIRATION",
              ),
              const SizedBox(height: 20),

              // Respiration Waveform Chart Card
              const LiveWaveformChart(),
              const SizedBox(height: 20),

              // Summary Metrics Grid Organism
              const SummaryMetricsGridOrganism(),
              const SizedBox(height: 28),

              // Physician Export Action Button
              AppButton(
                label: "Export Signed Report for Physician",
                variant: AppButtonVariant.secondary,
                icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.textPrimary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Exporting Signed FHIR JSON / PDF Clinical Report..."),
                      backgroundColor: AppColors.purpleAnalytics,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
