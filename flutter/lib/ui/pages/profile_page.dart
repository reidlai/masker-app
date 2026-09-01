import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../molecules/history_tile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Profile Header
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.cardBg,
                child: Icon(Icons.person, size: 50, color: AppColors.primaryTeal),
              ),
              const SizedBox(height: 12),
              const Text(
                "Alex Johnson",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                "ID: 00207061300",
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Section Title & Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("History Records", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Row(
                      children: [
                        Text("Filter by Date ", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // History Record List
              const HistoryTile(
                date: "Oct 26, 2026",
                time: "10:30 AM",
                duration: "25m",
                spO2: "98",
                heartRate: "71",
              ),
              const HistoryTile(
                date: "Oct 25, 2026",
                time: "09:15 AM",
                duration: "30m",
                spO2: "97",
                heartRate: "74",
              ),
              const SizedBox(height: 16),

              // Paired Device Card
              Align(
                alignment: Alignment.centerLeft,
                child: const Text("Wearable Device", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.masks, color: AppColors.primaryTeal),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Connected", style: TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text("Dennis Masker v1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
