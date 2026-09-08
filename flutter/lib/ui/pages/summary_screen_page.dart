import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/shad_button.dart';
import '../organisms/live_waveform_chart.dart';
import '../organisms/report_header_organism.dart';
import '../organisms/sleep_score_organism.dart';
import '../organisms/summary_metrics_grid_organism.dart';
import 'export_doctor_page.dart';
import 'graph_waveform_page.dart';
import 'history_filter_page.dart';

class SummaryScreenPage extends StatelessWidget {
  final VoidCallback? onOpenHistory;

  const SummaryScreenPage({
    super.key,
    this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Morning Sleep Summary"),
        leading: ModalRoute.of(context)?.canPop == true
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
            onPressed: () {
              if (onOpenHistory != null) {
                onOpenHistory!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HistoryFilterPage(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
              const SizedBox(height: 12),

              // Apnea-only caveat disclosure
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  "* Apnea Index scores apnea events per hour recorded by D-BAND thermal sensor. Not a full polysomnography AHI.",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Respiration Waveform Chart Header & Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "RESPECTIVE WAVEFORM",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.04,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GraphWaveformPage(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "Full Graph",
                          style: TextStyle(fontSize: 12, color: AppColors.accentGreen, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.accentGreen),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const LiveWaveformChart(),
              const SizedBox(height: 20),

              // Summary Metrics Grid Organism
              const SummaryMetricsGridOrganism(),
              const SizedBox(height: 28),

              // Physician Export Action Button
              ShadButton(
                label: "Export Signed Report for Physician",
                variant: ShadButtonVariant.outline,
                icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.textPrimary, size: 18),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExportDoctorPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
