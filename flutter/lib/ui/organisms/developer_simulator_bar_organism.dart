import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/ble/ble_simulator_driver.dart';
import '../../core/bloc/simulator/simulator_bloc.dart';
import '../../core/bloc/simulator/simulator_event.dart';
import '../../core/bloc/simulator/simulator_state.dart';
import '../../core/theme/app_theme.dart';

/// Developer/QA in-session scenario toolbar. **Renders nothing** (`SizedBox`)
/// when `SimulatorBloc.isSimulatorActive` is false — the whole bar is
/// meaningless with the simulator off, so it is safe to place unconditionally
/// (do not wrap it in a `Padding`/`SizedBox` that would then show empty space).
///
/// [showEvenIfInactive] overrides that gate — set it from an explicit
/// developer/demo flag (`MeasurementPage.developerEnabled`) when the bar must
/// stay visible regardless of the live simulator state.
class DeveloperSimulatorBarOrganism extends StatelessWidget {
  final bool showEvenIfInactive;

  const DeveloperSimulatorBarOrganism({super.key, this.showEvenIfInactive = false});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        bool hasProvider = false;
        try {
          ctx.read<SimulatorBloc>();
          hasProvider = true;
        } catch (_) {}

        Widget barContent(BuildContext bCtx) {
          return BlocBuilder<SimulatorBloc, SimulatorState>(
            builder: (context, state) {
              // Developer-only: the whole bar is meaningless with the simulator
              // off. Self-gate so "simulator off ⟹ no toolbar" holds at every
              // call site — unless an explicit developer/demo flag forces it.
              if (!state.isSimulatorActive && !showEvenIfInactive) {
                return const SizedBox.shrink();
              }

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
                ),
              );
            },
          );
        }

        if (hasProvider) {
          return barContent(ctx);
        } else {
          return BlocProvider<SimulatorBloc>(
            create: (_) => SimulatorBloc(),
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
          context.read<SimulatorBloc>().add(const SimulatorStopped());
        } else {
          context.read<SimulatorBloc>().add(SimulatorScenarioStarted(scenario));
        }
      },
    );
  }
}
