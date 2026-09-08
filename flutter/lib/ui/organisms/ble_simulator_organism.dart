import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/ble/ble_simulator_driver.dart';
import '../../core/bloc/simulator/simulator_bloc.dart';
import '../../core/bloc/simulator/simulator_event.dart';
import '../../core/bloc/simulator/simulator_state.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';

class BleSimulatorOrganism extends StatelessWidget {
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

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<SimulatorBloc, SimulatorState>(
      builder: (context, state) {
        final isEnabled = state.isSimulatorActive;
        final activeScenario = state.currentScenario;
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
                      context.read<SimulatorBloc>().add(SimulatorEnabledSet(val));
                      onSimulatorToggled?.call(val);
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
                              context.read<SimulatorBloc>().add(SimulatorScenarioStarted(SimulatorScenario.idleBandSample));
                              onSimulateIdleBandSample?.call();
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
                              context.read<SimulatorBloc>().add(SimulatorScenarioStarted(SimulatorScenario.normalRespiration));
                              onSimulateNormalBreathing?.call();
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
                              context.read<SimulatorBloc>().add(SimulatorScenarioStarted(SimulatorScenario.inBandNoExcursion));
                              onSimulateInBandNoExcursion?.call();
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
                              context.read<SimulatorBloc>().add(SimulatorScenarioStarted(SimulatorScenario.recovery));
                              onSimulateRecovery?.call();
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
  }

  @override
  Widget build(BuildContext context) {
    try {
      context.read<SimulatorBloc>();
      return _buildContent(context);
    } catch (_) {
      return BlocProvider(
        create: (_) => SimulatorBloc(),
        child: _buildContent(context),
      );
    }
  }
}
