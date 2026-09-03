import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../molecules/metric_card.dart';
import '../organisms/health_insights_organism.dart';
import '../organisms/user_header_organism.dart';
import '../organisms/weekly_calendar_organism.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onOpenSettings;
  final String firstName;
  final String? lastName;
  final String? avatarUrl;

  const HomePage({
    super.key,
    this.onOpenSettings,
    this.firstName = "David",
    this.lastName = "Miller",
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Header Organism
              UserHeaderOrganism(
                firstName: firstName,
                lastName: lastName,
                avatarUrl: avatarUrl,
                subtitle: "Sep. 28, 2026",
                onTap: onOpenSettings,
                onNotificationTap: () {},
              ),
              const SizedBox(height: 24),
              
              // Top Metrics Cards Row
              const Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: "Respiration",
                      value: "16",
                      unit: "bpm",
                      icon: Icons.air,
                      accentColor: AppColors.accentGreen,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: "SpO2",
                      value: "98",
                      unit: "%",
                      icon: Icons.water_drop,
                      accentColor: AppColors.primaryTeal,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: "HR",
                      value: "72",
                      unit: "bpm",
                      icon: Icons.favorite,
                      accentColor: AppColors.accentPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calendar Horizontal Section Organism
              const WeeklyCalendarOrganism(),
              const SizedBox(height: 24),

              // Health Articles Section Organism
              const HealthInsightsOrganism(),
            ],
          ),
        ),
      ),
    );
  }
}
