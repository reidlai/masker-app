import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/ble/ble_simulator_driver.dart';
import '../../core/bloc/simulator/simulator_cubit.dart';
import '../../core/bloc/simulator/simulator_state.dart';
import '../../core/theme/app_theme.dart';

class DeveloperSimulatorBarOrganism extends StatelessWidget {
  const DeveloperSimulatorBarOrganism({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        bool hasProvider = false;
        try {
          ctx.read<SimulatorCubit>();
          hasProvider = true;
        } catch (_) {}

        Widget barContent(BuildContext bCtx) {
          return BlocBuilder<SimulatorCubit, SimulatorState>(
            builder: (context, state) {
              final isSimEnabled = state.isSimulatorActive;
              final activeScenario = state.currentScenario;

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
                      ],
                    ),
                    if (isSimEnabled) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(
                            context,
                            label: "Stop Breathing during sleep",
                            scenario: SimulatorScenario.inBandNoExcursion,
                            activeScenario: activeScenario,
                            color: AppColors.dangerRed,
                          ),
                          _buildChip(
                            context,
                            label: "Normal Breathing during sleep",
                            scenario: SimulatorScenario.normalRespiration,
                            activeScenario: activeScenario,
                            color: AppColors.accentGreen,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        }

        if (hasProvider) {
          return barContent(ctx);
        } else {
          return BlocProvider<SimulatorCubit>(
            create: (_) => SimulatorCubit(),
            child: Builder(builder: (bCtx) => barContent(bCtx)),
          );
        }
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
          context.read<SimulatorCubit>().stopSimulation();
        } else {
          context.read<SimulatorCubit>().startSimulationScenario(scenario);
        }
      },
    );
  }
}
