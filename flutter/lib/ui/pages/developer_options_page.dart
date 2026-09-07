import 'package:flutter/material.dart';
import '../../core/ble/ble_simulator_driver.dart';
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

              // Master Telemetry Simulator Toggle Card
              StreamBuilder<bool>(
                stream: BleSimulatorDriver().isSimulatorStream,
                initialData: BleSimulatorDriver().isSimulatorActive,
                builder: (context, snapshot) {
                  final isSimActive = snapshot.data ?? true;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "BLE Telemetry Simulator",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Simulate continuous Sensor Baseline Drift & Noise Floor Envelope detection and synthetic breathing telemetry",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isSimActive,
                          activeThumbColor: AppColors.accentGreen,
                          onChanged: (val) {
                            BleSimulatorDriver().setSimulatorEnabled(val);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // BleSimulatorOrganism
              BleSimulatorOrganism(
                onSimulateInBandNoExcursion: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Simulating In-Band (no excursion) stretch — apnea breach after >10s"),
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
