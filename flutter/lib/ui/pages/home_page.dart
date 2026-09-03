import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../molecules/metric_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
              // User Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.cardBg,
                        child: Icon(Icons.person, color: AppColors.primaryTeal),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Good Morning, Alex!",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Sep. 28, 2026", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
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

              // Calendar Horizontal Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Weekly", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Row(
                          children: [
                            Text("< Monthly >", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (index) {
                        final days = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
                        final dates = [7, 8, 9, 10, 11, 12, 13];
                        final isSelected = index == 5;
                        return Column(
                          children: [
                            Text(days[index], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${dates[index]}",
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Health Articles Section
              const Text("Health & Mask Insights", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 12),
                  Expanded(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
