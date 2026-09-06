import 'package:flutter/material.dart';
import '../../core/ble/ble_simulator_driver.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';

class BleSimulatorOrganism extends StatefulWidget {
  final ValueChanged<bool>? onSimulatorToggled;
  final VoidCallback? onSimulateIdleBandSample;
  final VoidCallback? onSimulateNormalBreathing;
  final VoidCallback? onSimulateInBandNoExcursion;
  final VoidCallback? onSimulateRecovery;

  const BleSimulatorOrganism({
    super.key,
    this.onSimulatorToggled,
    this.onSimulateIdleBandSample,
    this.onSimulateNormalBreathing,
    this.onSimulateInBandNoExcursion,
    this.onSimulateRecovery,
  });

  @override
  State<BleSimulatorOrganism> createState() => _BleSimulatorOrganismState();
}

class _BleSimulatorOrganismState extends State<BleSimulatorOrganism> {
  final BleSimulatorDriver _telemetryService = BleSimulatorDriver();

  String _getScenarioName(SimulatorScenario scenario) {
    switch (scenario) {
      case SimulatorScenario.idleBandSample:
        return "Sampling IDLE Band (worn idle ~10s)";
      case SimulatorScenario.normalRespiration:
        return "Streaming Normal Respiration Waveform (16 bpm)";
      case SimulatorScenario.inBandNoExcursion:
        return "In-Band, No Excursion (>10s stop-breathing stretch)";
      case SimulatorScenario.recovery:
        return "Patient Breathing Recovery Active (5s Auto-Silence)";
      case SimulatorScenario.none:
        return "Ready (Background Stream Active)";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _telemetryService.isSimulatorStream,
      initialData: _telemetryService.isSimulatorActive,
      builder: (context, isSimSnapshot) {
        final isEnabled = isSimSnapshot.data ?? true;

        return StreamBuilder<SimulatorScenario>(
          stream: _telemetryService.scenarioStream,
          initialData: _telemetryService.currentScenario,
          builder: (context, scenarioSnapshot) {
            final activeScenario = scenarioSnapshot.data ?? SimulatorScenario.none;
            final statusText = isEnabled ? _getScenarioName(activeScenario) : "Disabled";

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.tune, color: AppColors.accentGreen, size: 24),
                          SizedBox(width: 10),
                          Text(
                            "BLE Signal Simulator",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isEnabled,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: (val) {
                          _telemetryService.setSimulatorEnabled(val);
                          widget.onSimulatorToggled?.call(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Active Status: $statusText",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: activeScenario == SimulatorScenario.inBandNoExcursion ? FontWeight.bold : FontWeight.normal,
                      color: activeScenario == SimulatorScenario.inBandNoExcursion ? Colors.redAccent : AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 24, color: AppColors.cardBorder),

                  // Calibration Section
                  const Text(
                    "1. Calibration Lifecycle Simulation",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: "Simulate IDLE Band Sample",
                          variant: activeScenario == SimulatorScenario.idleBandSample ? AppButtonVariant.primary : AppButtonVariant.secondary,
                          onPressed: isEnabled
                              ? () {
                                  _telemetryService.startSimulationScenario(SimulatorScenario.idleBandSample);
                                  widget.onSimulateIdleBandSample?.call();
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sleep Cycle Section
                  const Text(
                    "2. Nocturnal Sleep Cycle Simulation",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.purpleAnalytics),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: "Simulate Normal Respiration (16 bpm)",
                          variant: activeScenario == SimulatorScenario.normalRespiration ? AppButtonVariant.primary : AppButtonVariant.secondary,
                          onPressed: isEnabled
                              ? () {
                                  _telemetryService.startSimulationScenario(SimulatorScenario.normalRespiration);
                                  widget.onSimulateNormalBreathing?.call();
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: "Simulate In-Band (no excursion) >10s",
                          variant: AppButtonVariant.danger,
                          onPressed: isEnabled
                              ? () {
                                  _telemetryService.startSimulationScenario(SimulatorScenario.inBandNoExcursion);
                                  widget.onSimulateInBandNoExcursion?.call();
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: "Simulate Patient Recovery (5s)",
                          variant: activeScenario == SimulatorScenario.recovery ? AppButtonVariant.primary : AppButtonVariant.secondary,
                          onPressed: isEnabled
                              ? () {
                                  _telemetryService.startSimulationScenario(SimulatorScenario.recovery);
                                  widget.onSimulateRecovery?.call();
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
