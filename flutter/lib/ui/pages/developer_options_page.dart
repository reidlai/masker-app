import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/ble/ble_receiver_service.dart';
import '../../core/bloc/auth/auth_bloc.dart';
import '../../core/bloc/auth/auth_event.dart';
import '../../core/bloc/simulator/simulator_bloc.dart';
import '../../core/bloc/simulator/simulator_event.dart';
import '../../core/bloc/simulator/simulator_state.dart';
import '../../core/theme/app_theme.dart';
import '../organisms/ble_simulator_organism.dart';
import '../organisms/settings_group_card_organism.dart';
import '../molecules/settings_menu_row.dart';

class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({super.key});

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(content, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Confirm Reset"),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
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
              BlocBuilder<SimulatorBloc, SimulatorState>(
                builder: (context, state) {
                  final isSimActive = state.isSimulatorActive;
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
                            context.read<SimulatorBloc>().add(SimulatorEnabledSet(val));
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

              // Onboarding & Reset Tools Card Organism
              SettingsGroupCardOrganism(
                sectionHeader: "Onboarding & Reset Tools",
                children: [
                  SettingsMenuRow(
                    leadingIcon: Icons.bluetooth_disabled,
                    label: "Unbind BLE Sensor Device",
                    valueText: "Reset Pairing",
                    onTap: () async {
                      final confirm = await _showConfirmDialog(
                        context,
                        title: "Unbind BLE Sensor?",
                        content: "Resets paired device address, clears noise floor envelope, and returns to initial scanning state.",
                      );
                      if (confirm == true) {
                        BleReceiverService().disconnect();
                        BleReceiverService().resetForTest();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("BLE Sensor Device unbound successfully."),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                  SettingsMenuRow(
                    leadingIcon: Icons.delete_forever,
                    label: "Unregister User Account",
                    valueText: "Full Reset",
                    onTap: () async {
                      final confirm = await _showConfirmDialog(
                        context,
                        title: "Unregister User Account?",
                        content: "Deletes local Passkey credentials, clears patient profile, and restarts Phase 1 Onboarding.",
                      );
                      if (confirm == true) {
                        try {
                          context.read<AuthBloc>().add(const AuthUnregisterRequested());
                        } catch (_) {}
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("User Account unregistered. Navigating to Onboarding..."),
                              backgroundColor: AppColors.accentGreen,
                            ),
                          );
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      }
                    },
                  ),
                ],
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

  @override
  Widget build(BuildContext context) {
    try {
      context.read<SimulatorBloc>();
      return _buildContent(context);
    } catch (_) {
      return BlocProvider(
        create: (_) => SimulatorBloc(),
        child: Builder(builder: (bCtx) => _buildContent(bCtx)),
      );
    }
  }
}
