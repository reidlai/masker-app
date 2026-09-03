import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../organisms/ble_simulator_organism.dart';
import '../organisms/settings_group_card_organism.dart';
import '../molecules/settings_menu_row.dart';

class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Developer Options"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hardware & Telemetry Simulator",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                "Simulate thermal BLE sensor streams for calibration testing and nocturnal apnea alarm evaluation.",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // BleSimulatorOrganism
              BleSimulatorOrganism(
                onSimulateApneaAlert: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Simulating Obstructive Apnea Breach Event (>10s drop)"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                },
                onSimulateRecovery: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Simulating Patient Breathing Recovery (5s continuous normal)"),
                      backgroundColor: AppColors.accentGreen,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Extra Developer Tools Group Card Organism
              SettingsGroupCardOrganism(
                sectionHeader: "System Diagnostics",
                children: const [
                  SettingsMenuRow(
                    leadingIcon: Icons.memory,
                    label: "Inspect Circular RAM Buffer (10Hz)",
                  ),
                  Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  SettingsMenuRow(
                    leadingIcon: Icons.security,
                    label: "Verify AES-128 BLE Link Encryption",
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
