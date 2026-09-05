import 'package:flutter/material.dart';
import '../../core/ble/ble_simulator_driver.dart';
import '../../core/theme/app_theme.dart';

class DeveloperSimulatorBarOrganism extends StatelessWidget {
  final BleSimulatorDriver _telemetryService = BleSimulatorDriver();

  DeveloperSimulatorBarOrganism({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _telemetryService.isSimulatorStream,
      initialData: _telemetryService.isSimulatorActive,
      builder: (context, isSimSnapshot) {
        final isSimEnabled = isSimSnapshot.data ?? true;

        return StreamBuilder<SimulatorScenario>(
          stream: _telemetryService.scenarioStream,
          initialData: _telemetryService.currentScenario,
          builder: (context, scenarioSnapshot) {
            final activeScenario = scenarioSnapshot.data ?? SimulatorScenario.none;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.tune, color: AppColors.accentGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "⚡ DEV SIMULATOR TOOLBAR",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isSimEnabled,
                        activeThumbColor: AppColors.accentGreen,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          _telemetryService.setSimulatorEnabled(val);
                        },
                      ),
                    ],
                  ),
                  if (isSimEnabled) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildChip(
                            context,
                            label: "Idle Noise",
                            scenario: SimulatorScenario.idleNoise,
                            activeScenario: activeScenario,
                            color: AppColors.primaryTeal,
                          ),
                          const SizedBox(width: 6),
                          _buildChip(
                            context,
                            label: "Active Baseline",
                            scenario: SimulatorScenario.activeBreath,
                            activeScenario: activeScenario,
                            color: AppColors.primaryTeal,
                          ),
                          const SizedBox(width: 6),
                          _buildChip(
                            context,
                            label: "Normal (16 bpm)",
                            scenario: SimulatorScenario.normalRespiration,
                            activeScenario: activeScenario,
                            color: AppColors.purpleAnalytics,
                          ),
                          const SizedBox(width: 6),
                          _buildChip(
                            context,
                            label: "Apnea Drop (>10s)",
                            scenario: SimulatorScenario.apneaAlert,
                            activeScenario: activeScenario,
                            color: AppColors.dangerRed,
                          ),
                          const SizedBox(width: 6),
                          _buildChip(
                            context,
                            label: "Recovery (5s)",
                            scenario: SimulatorScenario.recovery,
                            activeScenario: activeScenario,
                            color: AppColors.accentGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required SimulatorScenario scenario,
    required SimulatorScenario activeScenario,
    required Color color,
  }) {
    final isSelected = activeScenario == scenario;

    return ActionChip(
      elevation: isSelected ? 4 : 0,
      backgroundColor: isSelected ? color : AppColors.cardBorder.withValues(alpha: 0.4),
      side: BorderSide(color: isSelected ? color : AppColors.cardBorder),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      onPressed: () {
        if (isSelected) {
          _telemetryService.stopSimulation();
        } else {
          _telemetryService.startSimulationScenario(scenario);
        }
      },
    );
  }
}
