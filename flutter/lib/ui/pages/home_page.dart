import 'package:flutter/material.dart';
import '../../core/ble/ble_simulator_driver.dart';
import '../../core/theme/app_theme.dart';
import '../molecules/device_status_card.dart';
import '../molecules/home_summary_card.dart';
import '../molecules/weekly_trend_card.dart';
import 'history_filter_page.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onOpenSummary;
  final VoidCallback? onOpenMonitor;
  final VoidCallback? onOpenHistory;

  const HomePage({
    super.key,
    this.onOpenSummary,
    this.onOpenMonitor,
    this.onOpenHistory,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 18) return "Good afternoon";
    return "Good evening";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1 — Greeting + Monitoring Streak
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "12 nights monitored",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // 2 — Last-Night Summary Hero Card
              HomeSummaryCard(
                dateText: "Sep 5, 2026",
                apneaIndex: 3.2,
                durationText: "7h 45m",
                eventCount: 2,
                onTap: onOpenSummary,
              ),
              const SizedBox(height: 12),

              // 3 — D-BAND Device Status Card (Reactive Stream)
              StreamBuilder<bool>(
                stream: BleSimulatorDriver().isSimulatorStream,
                initialData: BleSimulatorDriver().isSimulatorActive,
                builder: (context, snapshot) {
                  final isConnected = snapshot.data ?? false;
                  return DeviceStatusCard(
                    state: isConnected
                        ? DeviceConnectionState.connected
                        : DeviceConnectionState.disconnected,
                    batteryLevel: isConnected ? 84 : 0,
                    lastSyncText: isConnected ? "Last sync 7:02 AM" : "Not connected",
                    onTap: onOpenMonitor,
                  );
                },
              ),
              const SizedBox(height: 12),

              // 4 — 7-Night Apnea Index Trend Card
              WeeklyTrendCard(
                weeklyScores: const [2.8, 3.1, 4.0, null, 3.5, 3.8, 3.2],
                averageScore: 3.4,
                priorWeekScore: 4.1,
                onTap: () {
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
        ),
      ),
    );
  }
}
